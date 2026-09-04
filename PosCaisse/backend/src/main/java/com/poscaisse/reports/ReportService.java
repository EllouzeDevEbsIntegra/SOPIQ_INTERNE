package com.poscaisse.reports;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.*;

/** Reporting straight from PostgreSQL (aggregations over paid/refunded/cancelled orders). */
@Service @RequiredArgsConstructor
@Transactional(readOnly = true)
public class ReportService {
    public static final ZoneId TZ = ZoneId.of("Africa/Tunis");
    private final NamedParameterJdbcTemplate jdbc;

    /** Sales that count as revenue: PAID / PARTIALLY_REFUNDED / REFUNDED (net of refunds). */
    private static final String SALES = "o.status in ('PAID','PARTIALLY_REFUNDED','REFUNDED')";

    private MapSqlParameterSource params(OffsetDateTime from, OffsetDateTime to, Long posId, Long registerId, Long cashierId) {
        return new MapSqlParameterSource().addValue("from", from).addValue("to", to).addValue("pos", posId).addValue("reg", registerId).addValue("cashier", cashierId);
    }

    private static String filters() {
        return " and o.paid_at >= :from and o.paid_at < :to and (:pos::bigint is null or o.point_of_sale_id = :pos) and (:reg::bigint is null or o.register_id = :reg) and (:cashier::bigint is null or o.cashier_id = :cashier) ";
    }

    public Map<String, Object> dashboard(OffsetDateTime from, OffsetDateTime to, Long posId, Long registerId, Long cashierId) {
        MapSqlParameterSource p = params(from, to, posId, registerId, cashierId);
        Map<String, Object> out = new LinkedHashMap<>();
        Map<String, Object> kpi = jdbc.queryForMap("select coalesce(sum(o.total - o.refunded_total),0) as revenue, count(*) as tickets, " +
                "coalesce(avg(o.total),0) as average_ticket, coalesce(sum(o.discount_amount + o.line_discount_total),0) as discounts, coalesce(sum(o.tax_total),0) as taxes, " +
                "coalesce(sum(o.refunded_total),0) as refunds from sale_order o where " + SALES + filters(), p);
        Map<String, Object> cancels = jdbc.queryForMap("select count(*) as cancellations, coalesce(sum(o.total),0) as cancellations_total from sale_order o where o.status='CANCELLED'" + filters(), p);
        kpi.putAll(cancels);
        kpi.put("items", jdbc.queryForObject("select coalesce(sum(l.quantity),0) from order_line l join sale_order o on o.id=l.order_id where l.parent_line_id is null and " + SALES + filters(), p, BigDecimal.class));
        out.put("kpi", kpi);
        out.put("byHour", jdbc.queryForList("select extract(hour from o.paid_at at time zone 'Africa/Tunis')::int as hour, count(*) as tickets, coalesce(sum(o.total - o.refunded_total),0) as revenue " +
                "from sale_order o where " + SALES + filters() + " group by 1 order by 1", p));
        out.put("byDay", jdbc.queryForList("select (o.paid_at at time zone 'Africa/Tunis')::date as day, count(*) as tickets, coalesce(sum(o.total - o.refunded_total),0) as revenue " +
                "from sale_order o where " + SALES + filters() + " group by 1 order by 1", p));
        out.put("byCategory", byCategory(p));
        out.put("topProducts", byProduct(p, 10));
        out.put("byCashier", jdbc.queryForList("select u.id, u.full_name as name, count(*) as tickets, coalesce(sum(o.total - o.refunded_total),0) as revenue " +
                "from sale_order o join app_user u on u.id=o.cashier_id where " + SALES + filters() + " group by 1,2 order by 3 desc", p));
        out.put("byRegister", jdbc.queryForList("select r.id, r.name, count(*) as tickets, coalesce(sum(o.total - o.refunded_total),0) as revenue " +
                "from sale_order o join register r on r.id=o.register_id where " + SALES + filters() + " group by 1,2 order by 3 desc", p));
        out.put("byPaymentMethod", byPaymentMethod(p));
        out.put("byServiceMode", jdbc.queryForList("select o.service_mode as mode, count(*) as tickets, coalesce(sum(o.total - o.refunded_total),0) as revenue from sale_order o where " + SALES + filters() + " group by 1 order by 3 desc", p));
        return out;
    }

    public List<Map<String, Object>> byCategory(MapSqlParameterSource p) {
        return jdbc.queryForList("select c.id, c.name, c.color, coalesce(sum(l.quantity),0) as quantity, coalesce(sum(l.line_total),0) as revenue " +
                "from order_line l join sale_order o on o.id=l.order_id left join category c on c.id=l.category_id where l.parent_line_id is null and " + SALES + filters() + " group by 1,2,3 order by 5 desc", p);
    }

    public List<Map<String, Object>> byProduct(MapSqlParameterSource p, int limit) {
        return jdbc.queryForList("select l.product_id as id, l.product_name as name, coalesce(sum(l.quantity),0) as quantity, coalesce(sum(l.line_total),0) as revenue, count(distinct o.id) as tickets " +
                "from order_line l join sale_order o on o.id=l.order_id where " + SALES + filters() + " group by 1,2 order by 3 desc " + (limit > 0 ? "limit " + limit : ""), p);
    }

    public List<Map<String, Object>> byPaymentMethod(MapSqlParameterSource p) {
        return jdbc.queryForList("select m.code, m.name, m.kind, count(*) as payments, coalesce(sum(pay.amount),0) as amount " +
                "from payment pay join payment_method m on m.id=pay.payment_method_id join sale_order o on o.id=pay.order_id where " + SALES + filters() + " group by 1,2,3 order by 5 desc", p);
    }

    public List<Map<String, Object>> report(String type, OffsetDateTime from, OffsetDateTime to, Long posId, Long registerId, Long cashierId) {
        MapSqlParameterSource p = params(from, to, posId, registerId, cashierId);
        return switch (type) {
            case "daily" -> jdbc.queryForList("select (o.paid_at at time zone 'Africa/Tunis')::date as day, count(*) as tickets, coalesce(sum(o.total - o.refunded_total),0) as revenue, " +
                    "coalesce(avg(o.total),0) as average_ticket, coalesce(sum(o.discount_amount + o.line_discount_total),0) as discounts, coalesce(sum(o.refunded_total),0) as refunds " +
                    "from sale_order o where " + SALES + filters() + " group by 1 order by 1 desc", p);
            case "hourly" -> jdbc.queryForList("select extract(hour from o.paid_at at time zone 'Africa/Tunis')::int as hour, count(*) as tickets, coalesce(sum(o.total - o.refunded_total),0) as revenue " +
                    "from sale_order o where " + SALES + filters() + " group by 1 order by 1", p);
            case "products" -> byProduct(p, 0);
            case "categories" -> byCategory(p);
            case "cashiers" -> jdbc.queryForList("select u.full_name as name, count(*) as tickets, coalesce(sum(o.total - o.refunded_total),0) as revenue, coalesce(avg(o.total),0) as average_ticket, coalesce(sum(o.discount_amount + o.line_discount_total),0) as discounts " +
                    "from sale_order o join app_user u on u.id=o.cashier_id where " + SALES + filters() + " group by 1 order by 3 desc", p);
            case "registers" -> jdbc.queryForList("select r.code, r.name, count(*) as tickets, coalesce(sum(o.total - o.refunded_total),0) as revenue " +
                    "from sale_order o join register r on r.id=o.register_id where " + SALES + filters() + " group by 1,2 order by 4 desc", p);
            case "pos" -> jdbc.queryForList("select s.code, s.name, count(*) as tickets, coalesce(sum(o.total - o.refunded_total),0) as revenue " +
                    "from sale_order o join point_of_sale s on s.id=o.point_of_sale_id where " + SALES + filters() + " group by 1,2 order by 4 desc", p);
            case "payments" -> byPaymentMethod(p);
            case "discounts" -> jdbc.queryForList("select o.ticket_number, o.paid_at, u.full_name as cashier, o.subtotal, o.line_discount_total, o.discount_percent, o.discount_amount, o.total " +
                    "from sale_order o join app_user u on u.id=o.cashier_id where (o.discount_amount > 0 or o.line_discount_total > 0) and " + SALES + filters() + " order by o.paid_at desc", p);
            case "cancellations" -> jdbc.queryForList("select o.ticket_number, o.paid_at, o.cancelled_at, u.full_name as cashier, cu.full_name as cancelled_by, o.total, o.cancel_reason " +
                    "from sale_order o join app_user u on u.id=o.cashier_id left join app_user cu on cu.id=o.cancelled_by where o.status='CANCELLED'" + filters() + " order by o.cancelled_at desc", p);
            case "refunds" -> jdbc.queryForList("select o.ticket_number, r.created_at, u.full_name as user_name, m.name as method, r.amount, r.reason, r.kind " +
                    "from refund r join sale_order o on o.id=r.order_id join app_user u on u.id=r.user_id join payment_method m on m.id=r.payment_method_id " +
                    "where r.created_at >= :from and r.created_at < :to and (:pos::bigint is null or o.point_of_sale_id = :pos) and (:reg::bigint is null or o.register_id = :reg) and (:cashier::bigint is null or r.user_id = :cashier) order by r.created_at desc", p);
            case "closures" -> jdbc.queryForList("select s.id, r.name as register, u.full_name as opened_by, s.opened_at, s.closed_at, s.opening_float, s.cash_sales, s.card_sales, s.other_sales, s.cash_in, s.cash_out, s.expected_cash, s.counted_cash, s.cash_difference, s.tickets_count, s.revenue " +
                    "from register_session s join register r on r.id=s.register_id join app_user u on u.id=s.opened_by where s.opened_at >= :from and s.opened_at < :to and (:pos::bigint is null or r.point_of_sale_id = :pos) and (:reg::bigint is null or s.register_id = :reg) and (:cashier::bigint is null or s.opened_by = :cashier) order by s.opened_at desc", p);
            case "differences" -> jdbc.queryForList("select s.id, r.name as register, u.full_name as opened_by, s.closed_at, s.expected_cash, s.counted_cash, s.cash_difference, s.closing_note " +
                    "from register_session s join register r on r.id=s.register_id join app_user u on u.id=s.opened_by where s.status='CLOSED' and s.cash_difference <> 0 and s.opened_at >= :from and s.opened_at < :to and (:pos::bigint is null or r.point_of_sale_id = :pos) and (:reg::bigint is null or s.register_id = :reg) and (:cashier::bigint is null or s.opened_by = :cashier) order by s.closed_at desc", p);
            case "movements" -> jdbc.queryForList("select m.created_at, r.name as register, u.full_name as user_name, m.movement_type as type, m.reason, m.amount, m.comment " +
                    "from cash_movement m join register_session s on s.id=m.session_id join register r on r.id=s.register_id join app_user u on u.id=m.user_id " +
                    "where m.created_at >= :from and m.created_at < :to and (:pos::bigint is null or r.point_of_sale_id = :pos) and (:reg::bigint is null or s.register_id = :reg) and (:cashier::bigint is null or m.user_id = :cashier) order by m.created_at desc", p);
            default -> throw new IllegalArgumentException("Rapport inconnu : " + type);
        };
    }

    public static OffsetDateTime startOf(LocalDate d) { return d.atStartOfDay(TZ).toOffsetDateTime(); }

    /** CSV export (UTF-8 with BOM, ';' separator — opens correctly in Excel FR). */
    public static String toCsv(List<Map<String, Object>> rows) {
        StringBuilder sb = new StringBuilder("﻿");
        if (rows.isEmpty()) return sb.toString();
        List<String> cols = new ArrayList<>(rows.get(0).keySet());
        sb.append(String.join(";", cols)).append("\r\n");
        for (Map<String, Object> r : rows) {
            List<String> vals = new ArrayList<>();
            for (String c : cols) {
                Object v = r.get(c);
                String s = v == null ? "" : v instanceof BigDecimal b ? b.toPlainString().replace('.', ',') : String.valueOf(v);
                if (s.contains(";") || s.contains("\"") || s.contains("\n")) s = "\"" + s.replace("\"", "\"\"") + "\"";
                vals.add(s);
            }
            sb.append(String.join(";", vals)).append("\r\n");
        }
        return sb.toString();
    }
}
