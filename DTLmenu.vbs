Option Explicit

Dim ROOT_DIR
Dim DTLKNOWSWHY_DIR
Dim DTLSAYSWHAT_DIR
Dim NETDTL_DIR
Dim GITDTL_DIR

Dim shell
Set shell = CreateObject("WScript.Shell")

If Not EnsureRootDir() Then
    WScript.Quit
End If

EnsurePyInstaller

MainMenu

Function EnsureRootDir()
    Dim fso, scriptFolder, guessedRoot, savedRoot

    Set fso = CreateObject("Scripting.FileSystemObject")
    scriptFolder = fso.GetParentFolderName(WScript.ScriptFullName)
    guessedRoot = fso.GetParentFolderName(scriptFolder)
    savedRoot = LoadSavedRoot(scriptFolder)

    If IsValidRoot(savedRoot) Then
        SetRootDir savedRoot
        EnsureRootDir = True
        Exit Function
    End If

    If IsValidRoot(guessedRoot) Then
        SetRootDir guessedRoot
        SaveRoot scriptFolder, guessedRoot
        EnsureRootDir = True
        Exit Function
    End If

    Do
        ROOT_DIR = BrowseForRoot("Selectionnez le dossier outils qui contient DTLKnowsWhy, DTLsaysWhat et GitDTL.")
        If ROOT_DIR = "" Then
            MsgBox "Dossier outils non configure. DTLmenu ne peut pas continuer.", vbExclamation, "DTLmenu"
            EnsureRootDir = False
            Exit Function
        End If

        If IsValidRoot(ROOT_DIR) Then
            SetRootDir ROOT_DIR
            SaveRoot scriptFolder, ROOT_DIR
            EnsureRootDir = True
            Exit Function
        End If

        MsgBox "Ce dossier ne contient pas tous les outils a reconstruire :" & vbCrLf & MissingTools(ROOT_DIR), vbExclamation, "DTLmenu"
    Loop
End Function

Sub SetRootDir(rootPath)
    ROOT_DIR = TrimTrailingSlash(rootPath)
    DTLKNOWSWHY_DIR = ROOT_DIR & "\DTLKnowsWhy"
    DTLSAYSWHAT_DIR = ROOT_DIR & "\DTLsaysWhat"
    NETDTL_DIR = ROOT_DIR & "\NetDTL"
    GITDTL_DIR = ROOT_DIR & "\GitDTL"
End Sub

Function LoadSavedRoot(scriptFolder)
    Dim fso, cfg, file
    Set fso = CreateObject("Scripting.FileSystemObject")
    cfg = scriptFolder & "\DTLmenu.root"
    If Not fso.FileExists(cfg) Then
        LoadSavedRoot = ""
        Exit Function
    End If
    Set file = fso.OpenTextFile(cfg, 1, False, -1)
    LoadSavedRoot = TrimTrailingSlash(Trim(file.ReadAll()))
    file.Close
End Function

Sub SaveRoot(scriptFolder, rootPath)
    Dim fso, file
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set file = fso.CreateTextFile(scriptFolder & "\DTLmenu.root", True, True)
    file.Write TrimTrailingSlash(rootPath)
    file.Close
End Sub

Function BrowseForRoot(message)
    Dim shellApp, folder
    Set shellApp = CreateObject("Shell.Application")
    Set folder = shellApp.BrowseForFolder(0, message, 0, 0)
    If folder Is Nothing Then
        BrowseForRoot = ""
    Else
        BrowseForRoot = TrimTrailingSlash(folder.Self.Path)
    End If
End Function

Function IsValidRoot(rootPath)
    IsValidRoot = (MissingTools(rootPath) = "")
End Function

Function MissingTools(rootPath)
    Dim fso, missing
    Set fso = CreateObject("Scripting.FileSystemObject")
    missing = ""
    If rootPath = "" Or Not fso.FolderExists(rootPath) Then
        MissingTools = "dossier outils"
        Exit Function
    End If
    AddMissingTool missing, rootPath, "DTLKnowsWhy"
    AddMissingTool missing, rootPath, "DTLsaysWhat"
    AddMissingTool missing, rootPath, "GitDTL"
    MissingTools = missing
End Function

Sub AddMissingTool(ByRef missing, rootPath, toolName)
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    If Not fso.FolderExists(rootPath & "\" & toolName) Then
        If missing <> "" Then missing = missing & vbCrLf
        missing = missing & toolName
    End If
End Sub

Function TrimTrailingSlash(value)
    Do While Len(value) > 0 And (Right(value, 1) = "\" Or Right(value, 1) = "/")
        value = Left(value, Len(value) - 1)
    Loop
    TrimTrailingSlash = value
End Function

Sub MainMenu()
    Dim choice

    Do
        choice = InputBox( _
            "MENU DE COMPILATION DTL" & vbCrLf & _
            String(32, "=") & vbCrLf & vbCrLf & _
            "1 - Reconstruire DTLKnowsWhy" & vbCrLf & _
            "2 - Reconstruire DTLsaysWhat" & vbCrLf & _
            "3 - NetDTL : information seulement" & vbCrLf & _
            "4 - Reconstruire GitDTL" & vbCrLf & vbCrLf & _
            "5 - Reconstruire les outils Python" & vbCrLf & _
            "6 - Ouvrir un dossier d'executables" & vbCrLf & _
            "7 - Verifier PyInstaller" & vbCrLf & vbCrLf & _
            "0 - Quitter", _
            "DTLmenu")

        choice = Trim(choice)

        If choice = "" Then
            Exit Do
        End If

        Select Case choice
            Case "1"
                BuildDTLKnowsWhy
            Case "2"
                BuildDTLsaysWhat
            Case "3"
                ShowNetDTLInfo
            Case "4"
                BuildGitDTL
            Case "5"
                BuildPythonTools
            Case "6"
                OpenExecutableFolderMenu
            Case "7"
                VerifyPyInstaller
            Case "0"
                Exit Do
            Case Else
                MsgBox "Choix inconnu.", vbExclamation, "DTLmenu"
        End Select
    Loop
End Sub

Sub BuildDTLKnowsWhy()
    If Not EnsurePyInstaller() Then Exit Sub
    RunCommands "Compilation DTLKnowsWhy", Array( _
        "cd /d " & Q(DTLKNOWSWHY_DIR), _
        "python -c ""import psutil, win32serviceutil; print('Dependances DTLKnowsWhy OK')""", _
        "python -m PyInstaller DTLknowsWhy.spec", _
        "python -m PyInstaller DTLknowsWhy-CLI.spec", _
        "cd /d " & Q(DTLKNOWSWHY_DIR & "\agent"), _
        "python -m PyInstaller --distpath " & Q("..\dist") & " --workpath " & Q("..\build\DTLknowsWhy-Agent") & " DTLknowsWhy-Agent.spec", _
        "echo.", _
        "echo Executables attendus :", _
        "echo " & DTLKNOWSWHY_DIR & "\dist\DTLknowsWhy.exe", _
        "echo " & DTLKNOWSWHY_DIR & "\dist\DTLknowsWhy-CLI.exe", _
        "echo " & DTLKNOWSWHY_DIR & "\dist\DTLknowsWhy-Agent.exe" _
    )
End Sub

Sub BuildDTLsaysWhat()
    If Not EnsurePyInstaller() Then Exit Sub
    RunCommands "Compilation DTLsaysWhat", Array( _
        "cd /d " & Q(DTLSAYSWHAT_DIR), _
        "python -c ""import wmi, psutil; print('Dependances DTLsaysWhat OK')""", _
        "python -m PyInstaller --onefile --console --name DTLsaysWhat DTLsaysWhat.py", _
        "echo.", _
        "echo Executable attendu :", _
        "echo " & DTLSAYSWHAT_DIR & "\dist\DTLsaysWhat.exe" _
    )
End Sub

Sub BuildGitDTL()
    If Not EnsurePyInstaller() Then Exit Sub
    RunCommands "Compilation GitDTL", Array( _
        "cd /d " & Q(GITDTL_DIR), _
        "python -m PyInstaller GitDTL.spec", _
        "echo.", _
        "echo Executable attendu :", _
        "echo " & GITDTL_DIR & "\dist\GitDTL.exe" _
    )
End Sub

Sub BuildPythonTools()
    If Not EnsurePyInstaller() Then Exit Sub
    RunCommands "Compilation des outils Python DTL", Array( _
        "cd /d " & Q(DTLKNOWSWHY_DIR), _
        "python -c ""import psutil, win32serviceutil; print('Dependances DTLKnowsWhy OK')""", _
        "python -m PyInstaller DTLknowsWhy.spec", _
        "python -m PyInstaller DTLknowsWhy-CLI.spec", _
        "cd /d " & Q(DTLKNOWSWHY_DIR & "\agent"), _
        "python -m PyInstaller --distpath " & Q("..\dist") & " --workpath " & Q("..\build\DTLknowsWhy-Agent") & " DTLknowsWhy-Agent.spec", _
        "cd /d " & Q(DTLSAYSWHAT_DIR), _
        "python -c ""import wmi, psutil; print('Dependances DTLsaysWhat OK')""", _
        "python -m PyInstaller --onefile --console --name DTLsaysWhat DTLsaysWhat.py", _
        "cd /d " & Q(GITDTL_DIR), _
        "python -m PyInstaller GitDTL.spec", _
        "echo.", _
        "echo Compilation terminee pour DTLKnowsWhy, DTLsaysWhat et GitDTL." _
    )
End Sub

Sub ShowNetDTLInfo()
    MsgBox _
        "NetDTL est une application PHP/MySQL." & vbCrLf & vbCrLf & _
        "Aucune reconstruction PyInstaller n'est necessaire." & vbCrLf & _
        "Le produit est deja publie / release." & vbCrLf & vbCrLf & _
        "Dossier :" & vbCrLf & NETDTL_DIR, _
        vbInformation, _
        "NetDTL"
End Sub

Sub OpenExecutableFolderMenu()
    Dim choice

    choice = InputBox( _
        "Ouvrir quel dossier ?" & vbCrLf & vbCrLf & _
        "1 - DTLKnowsWhy\dist" & vbCrLf & _
        "2 - DTLsaysWhat\dist" & vbCrLf & _
        "3 - GitDTL\dist" & vbCrLf & _
        "4 - Dossier outils" & vbCrLf & vbCrLf & _
        "0 - Retour", _
        "Executables")

    choice = Trim(choice)

    Select Case choice
        Case "1"
            OpenFolder DTLKNOWSWHY_DIR & "\dist"
        Case "2"
            OpenFolder DTLSAYSWHAT_DIR & "\dist"
        Case "3"
            OpenFolder GITDTL_DIR & "\dist"
        Case "4"
            OpenFolder ROOT_DIR
        Case "0", ""
            Exit Sub
        Case Else
            MsgBox "Choix inconnu.", vbExclamation, "DTLmenu"
    End Select
End Sub

Sub VerifyPyInstaller()
    If Not EnsurePyInstaller() Then Exit Sub
    RunCommands "Verification PyInstaller", Array( _
        "cd /d " & Q(ROOT_DIR), _
        "python --version", _
        "python -m PyInstaller --version", _
        "echo.", _
        "echo Si une version PyInstaller s'affiche, l'environnement est pret." _
    )
End Sub

Function EnsurePyInstaller()
    If Not CommandSucceeds("python --version") Then
        EnsurePyInstaller = OfferPythonInstall()
        Exit Function
    End If

    If CommandSucceeds("python -m PyInstaller --version") Then
        EnsurePyInstaller = True
        Exit Function
    End If

    EnsurePyInstaller = OfferPyInstallerInstall()
End Function

Function OfferPythonInstall()
    Dim answer
    answer = MsgBox( _
        "Python est introuvable." & vbCrLf & vbCrLf & _
        "Voulez-vous lancer son installation avec winget ?" & vbCrLf & vbCrLf & _
        "Commande : winget install --id Python.Python.3.12 -e --source winget", _
        vbQuestion + vbYesNo, _
        "DTLmenu")

    If answer = vbYes Then
        RunInstallScript "DTLmenu_install_python.cmd", Array( _
            "@echo off", _
            "chcp 65001 >nul", _
            "title Installation Python", _
            "echo Installation de Python avec winget", _
            "echo ================================================================", _
            "winget install --id Python.Python.3.12 -e --source winget", _
            "echo.", _
            "echo Si Python vient d etre installe, fermez puis relancez DTLmenu.", _
            "echo.", _
            "pause" _
        )
    End If

    OfferPythonInstall = False
End Function

Function OfferPyInstallerInstall()
    Dim answer
    answer = MsgBox( _
        "PyInstaller est introuvable." & vbCrLf & vbCrLf & _
        "Voulez-vous l'installer maintenant ?" & vbCrLf & vbCrLf & _
        "Commande : python -m pip install --upgrade pyinstaller", _
        vbQuestion + vbYesNo, _
        "DTLmenu")

    If answer = vbYes Then
        RunInstallScript "DTLmenu_install_pyinstaller.cmd", Array( _
            "@echo off", _
            "chcp 65001 >nul", _
            "title Installation PyInstaller", _
            "echo Installation de PyInstaller", _
            "echo ================================================================", _
            "python -m pip install --upgrade pip", _
            "python -m pip install --upgrade pyinstaller", _
            "echo.", _
            "python -m PyInstaller --version", _
            "echo.", _
            "echo Si une version s'affiche ci-dessus, PyInstaller est installe.", _
            "echo Vous pouvez relancer la compilation dans DTLmenu.", _
            "echo.", _
            "pause" _
        )
    End If

    OfferPyInstallerInstall = False
End Function

Sub RunInstallScript(scriptName, lines)
    Dim fso, tempFolder, scriptPath, file, i

    Set fso = CreateObject("Scripting.FileSystemObject")
    tempFolder = shell.ExpandEnvironmentStrings("%TEMP%")
    scriptPath = tempFolder & "\" & scriptName

    Set file = fso.CreateTextFile(scriptPath, True)
    For i = 0 To UBound(lines)
        file.WriteLine lines(i)
    Next
    file.Close

    shell.Run Q(scriptPath), 1, False
End Sub

Function CommandSucceeds(commandLine)
    CommandSucceeds = (shell.Run("%ComSpec% /c " & Q(commandLine & " >nul 2>&1"), 0, True) = 0)
End Function

Sub OpenFolder(folderPath)
    If FolderExists(folderPath) Then
        shell.Run "explorer.exe " & Q(folderPath), 1, False
    Else
        MsgBox "Dossier introuvable :" & vbCrLf & folderPath, vbExclamation, "DTLmenu"
    End If
End Sub

Sub RunCommands(title, commands)
    Dim fso, tempFolder, scriptPath, file, i, exitCode

    Set fso = CreateObject("Scripting.FileSystemObject")
    tempFolder = shell.ExpandEnvironmentStrings("%TEMP%")
    scriptPath = tempFolder & "\DTLmenu_run.cmd"

    Set file = fso.CreateTextFile(scriptPath, True)
    file.WriteLine "@echo off"
    file.WriteLine "chcp 65001 >nul"
    file.WriteLine "title " & title
    file.WriteLine "echo " & title
    file.WriteLine "echo " & String(72, "=")
    file.WriteLine "echo."

    For i = 0 To UBound(commands)
        file.WriteLine commands(i)
        If IsBuildCommand(commands(i)) Then
            file.WriteLine "if errorlevel 1 goto error"
        End If
    Next

    file.WriteLine "echo."
    file.WriteLine "echo Operation terminee."
    file.WriteLine "goto end"
    file.WriteLine ":error"
    file.WriteLine "echo."
    file.WriteLine "echo ERREUR : la derniere commande a echoue."
    file.WriteLine ":end"
    file.WriteLine "echo."
    file.WriteLine "pause"
    file.Close

    exitCode = shell.Run(Q(scriptPath), 1, True)

    On Error Resume Next
    fso.DeleteFile scriptPath, True
    On Error GoTo 0
End Sub

Function IsBuildCommand(commandLine)
    Dim lower
    lower = LCase(commandLine)
    IsBuildCommand = (InStr(lower, "python -m pyinstaller") > 0 Or InStr(lower, "python --version") > 0 Or InStr(lower, "python -c") > 0)
End Function

Function FolderExists(folderPath)
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    FolderExists = fso.FolderExists(folderPath)
End Function

Function Q(value)
    Q = Chr(34) & value & Chr(34)
End Function
