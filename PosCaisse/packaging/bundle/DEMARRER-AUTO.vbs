' PosCaisse - ouverture de la caisse SANS fenetre noire.
'
' A utiliser dans le dossier Demarrage de Windows (touche Windows + R, puis
' "shell:startup"), a la place d'un raccourci vers DEMARRER.bat : Windows ouvre
' toujours une console pour un fichier .bat, jamais pour un fichier .vbs.
'
' Le chemin n'est pas ecrit en dur : ce fichier se repere tout seul. Il suit donc
' le dossier PosCaisse si on le deplace ou si on le renomme.
'
' Une caisse qui demarre en silence echoue aussi en silence. C'est tout l'objet du
' bloc If : on attend la fin du demarrage, et si quelque chose bloque, on le dit
' au lieu de laisser le personnel devant un navigateur en erreur.

Option Explicit
Dim fso, shell, racine, cmd, code

Set fso   = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")
racine    = fso.GetParentFolderName(WScript.ScriptFullName)

cmd = "powershell -NoProfile -ExecutionPolicy Bypass -File """ & racine & "\outils\poscaisse.ps1"" -Action start"

' 0 = fenetre masquee, True = on attend la fin pour connaitre le resultat.
code = shell.Run(cmd, 0, True)

If code <> 0 Then
  MsgBox "La caisse n'a pas demarre." & vbCrLf & vbCrLf & _
         "Lancez ETAT.bat dans le dossier :" & vbCrLf & _
         racine & vbCrLf & vbCrLf & _
         "Il dira ce qui bloque.", _
         vbExclamation, "PosCaisse"
End If
