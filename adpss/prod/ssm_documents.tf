/*
resource "aws_ssm_document" "create_user" {
  name          = "adpss-create-user-ps1"
  document_type = "Command"
  document_format  = "YAML"
  target_type="/AWS::EC2::Instance"
  content = <<EOT
      ---
      schemaVersion: "2.2"
      description: "Create new User in adpss server"
      parameters:
        UserName:
          type: "String"
          description: "(Required): New Username"
        FullName:
          type: "String"
          description: "(Required): Enter Firstname Lastname"
        Description:
          type: "String"
          description: "(Optional): Enter Description of the user (Ex: IMPAQ User, Pantheon, etc)"
          default: "IMPAQ"
        Groups:
          type: "String"
          description: "Groups to add user to."
          default: "Users, Remote Desktop Users"
      mainSteps:
      - action: "aws:runPowerShellScript"
        name: "createuser"
        inputs:
          runCommand:
          - Add-Type -AssemblyName System.Web
          - $Password = [System.Web.Security.Membership]::GeneratePassword(15,2)
          - $SecurePwd = ConvertTo-SecureString -String $Password -AsPlainText -Force
          - New-LocalUser -Name "{{ UserName }}" -Password $SecurePwd -FullName "{{ FullName }}" -Description "{{ Description }}"
          - Add-LocalGroupMember -Group "Users" -Member "{{ UserName }}"
          - Add-LocalGroupMember -Group "Remote Desktop Users" -Member "{{ UserName }}"
          - Write-Host "Temp Password is - " $Password
    EOT
}*/
