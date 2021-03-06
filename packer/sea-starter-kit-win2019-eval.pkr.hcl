# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.


variable "landing_page" {
  type    = string
}

variable "archive_name" {
  type = string
}

variable "web_api" {
  type = string
}

variable "admin_app" {
  type = string
}

variable "swagger_ui" {
  type = string
}

variable "databases" {
  type = string
}

variable "postman" {
  type = string
}

variable "sampledata" {
  type    = string
}

variable "cpus" {
  type = string
}

variable "debug_mode" {
  type = string
}

variable "disk_size" {
  type = string
}

variable "headless" {
  type = string
}

variable "hw_version" {
  type = string
}

variable "memory" {
  type = string
}

variable "shutdown_command" {
  type = string
}

variable "vm_name" {
  type = string
}

variable "vm_switch" {
  type = string
}

variable "distribution_directory" {
  type = string
}

variable "user_name" {
  type = string
}

variable "password" {
  type = string
}

variable "base_image_directory" {
  type = string
}

variable "starter_kit_directory" {
  type = string
}

variable "sample_report" {
  type = string
}

variable "sample_validation" {
  type = string
}

packer {
  required_plugins {
    comment = {
      version = ">=v0.2.23"
      source = "github.com/sylviamoss/comment"
    }
  }
}

source "hyperv-vmcx" "sea-starter-kit" {
  clone_from_vmcx_path = "${path.root}/${var.base_image_directory}/"
  communicator         = "winrm"
  cpus                 = "${var.cpus}"
  headless             = "${var.headless}"
  memory               = "${var.memory}"
  shutdown_command     = "${var.shutdown_command}"
  switch_name          = "${var.vm_switch}"
  vm_name              = "${var.vm_name}"
  winrm_password       = "${var.password}"
  winrm_timeout        = "10000s"
  winrm_username       = "${var.user_name}"
  output_directory     = "${path.root}/${var.distribution_directory}"
}

build {
  sources = ["source.hyperv-vmcx.sea-starter-kit"]

  provisioner "comment" {
    comment     = "Copying ${var.archive_name}.zip to c:/temp"
    ui          = true
    bubble_text = false
  }

  provisioner "file" {
    destination = "c:/temp/"
    sources     = [
      "${path.root}/build/${var.landing_page}.zip",
      "${path.root}/build/${var.archive_name}.zip",
      "${path.root}/build/${var.sample_report}.zip",
      "${path.root}/build/${var.sample_validation}.zip",
      "${path.root}/build/${var.web_api}.zip",
      "${path.root}/build/${var.admin_app}.zip",
      "${path.root}/build/${var.swagger_ui}.zip",
      "${path.root}/build/${var.databases}.zip",
      "${path.root}/build/${var.sampledata}.zip",
      "${path.root}/build/${var.postman}.zip"
    ]
  }

  provisioner "comment" {
    comment     = "Extracting ${var.archive_name}.zip to c:/temp/${var.archive_name}"
    ui          = true
    bubble_text = false
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.password}"
    elevated_user     = "${var.user_name}"
    inline            = [
      "$ErrorActionPreference = 'Stop'",
      "Set-Location c:/temp",
      "Expand-Archive ./${var.archive_name}.zip -Destination ./${var.archive_name}"
    ]
  }

  provisioner "comment" {
    comment     = "Extracting ${var.landing_page}.zip to desktop"
    ui          = true
    bubble_text = false
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.password}"
    elevated_user     = "${var.user_name}"
    inline            = [
        "Set-Location c:/temp",
        "Expand-Archive ./${var.landing_page}.zip -Destination ./${var.landing_page}",
        "((Get-Content -path \"./${var.landing_page}/docs/SEA Modernization Starter Kit.html\" -Raw) -replace '@@DOMAINNAME@@',[Environment]::MachineName) | Set-Content -Path \"./${var.landing_page}/docs/SEA Modernization Starter Kit.html\"",
        "Copy-Item -Recurse -Path ./${var.landing_page}/docs/ -Destination c:/${var.starter_kit_directory}/LandingPage",
        "$WshShell = New-Object -comObject WScript.Shell",
        "$Shortcut = $WshShell.CreateShortcut(\"C:/Users/Public/Desktop/Start Here.lnk\")",
        "$Shortcut.TargetPath = \"c:/${var.starter_kit_directory}/LandingPage/SEA Modernization Starter Kit.html\"",
        "$Shortcut.IconLocation = \"https://edfidata.s3-us-west-2.amazonaws.com/Starter+Kits/images/favicon.ico\"",
        "$Shortcut.Save()"
    ]
  }

  provisioner "comment" {
    comment     = "Extracting ${var.sample_report}.zip to c:/${var.starter_kit_directory}/${var.sample_report}"
    ui          = true
    bubble_text = false
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.password}"
    elevated_user     = "${var.user_name}"
    inline            = [
      "$ErrorActionPreference = 'Stop'",
      "Set-Location c:/temp",
      "Expand-Archive ./${var.sample_report}.zip -Destination c:/${var.starter_kit_directory}/${var.sample_report}"
    ]
  }

  provisioner "comment" {
    comment     = "Installing Databases"
    ui          = true
    bubble_text = false
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.password}"
    elevated_user     = "${var.user_name}"
    inline            = [
      "$ErrorActionPreference = 'Stop'",
      "New-Item -Path c:/ -Name plugin -ItemType directory",
      "Set-Location c:/temp",
      "Expand-Archive ./${var.databases}.zip -Destination ./${var.databases}",
      "Expand-Archive ./${var.sampledata}.zip -Destination ./${var.sampledata}",
      "Expand-Archive ./${var.sample_validation}.zip -Destination ./${var.sample_validation}",
      "Copy-Item -Path ./${var.archive_name}/configuration.json -Destination ./${var.databases}",
      "Copy-Item -Path ./${var.archive_name}/sampledata.ps1 -Destination ./${var.databases}/Ed-Fi-ODS-Implementation/DatabaseTemplate/Scripts/",
      "Copy-Item -Path ./${var.archive_name}/sk.ps1 -Destination c:/plugin -Force",
      "Copy-Item -Path ./${var.databases}/Ed-Fi-ODS-Implementation/Plugin/tpdm.ps1 -Destination c:/plugin -Force",
      "New-Item -ItemType Directory -Path ./${var.databases}/Ed-Fi-ODS-Implementation/Artifacts/MsSql/Structure/Ods/",
      "Get-ChildItem c:/${var.starter_kit_directory}/${var.sample_report}/* -filter '*-Create*.sql' | Move-Item -Destination ./${var.databases}/Ed-Fi-ODS-Implementation/Artifacts/MsSql/Structure/Ods/",
      "Copy-Item ./${var.sample_validation}/* ./${var.databases}/Ed-Fi-ODS-Implementation/Artifacts/MsSql/Structure/Ods/ -filter '*.sql' -recurse",
      "Set-Location ./${var.databases}",
      "Import-Module -Force -Scope Global SqlServer",
      "Import-Module ./Deployment.psm1",
      "Initialize-DeploymentEnvironment"
    ]
  }

  provisioner "comment" {
    comment          = "Executing c:/${var.starter_kit_directory}/${var.sample_report}/report.ps1"
    ui               = true
    bubble_text      = false
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.password}"
    elevated_user     = "${var.user_name}"
    inline            = [
      "$ErrorActionPreference = 'Stop'",
      "Set-Location c:/${var.starter_kit_directory}/${var.sample_report}",
      "./report.ps1"
    ]
  }

  provisioner "comment" {
    comment     = "Postman Setup"
    ui          = true
    bubble_text = false
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.password}"
    elevated_user     = "${var.user_name}"
    inline            = [
      "$ErrorActionPreference = 'Stop'",
      "Set-Location c:/temp",
      "Expand-Archive ./${var.postman}.zip -Destination c:/${var.starter_kit_directory}/Postman",
      "Set-Location c:/temp/${var.archive_name}",
      "./postman-setup.ps1"
    ]
  }

  provisioner "comment" {
    comment     = "Installing ODS/API"
    ui          = true
    bubble_text = false
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.password}"
    elevated_user     = "${var.user_name}"
    inline            = [
      "$ErrorActionPreference = 'Stop'",
      "Set-Location c:/temp",
      "Expand-Archive ./${var.web_api}.zip -Destination ./${var.web_api}",
      "Set-Location c:/temp/${var.archive_name}/installers",
      "./Install-WebApi.ps1",
      "Copy-Item -Path c:/temp/${var.archive_name}/webapi.appsettings.production.json -Destination C:/inetpub/Ed-Fi/WebApi/appsettings.production.json"
    ]
  }

  provisioner "comment" {
    comment     = "Installing SwaggerUI"
    ui          = true
    bubble_text = false
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.password}"
    elevated_user     = "${var.user_name}"
    inline            = [
      "$ErrorActionPreference = 'Stop'",
      "Set-Location c:/temp",
      "Expand-Archive ./${var.swagger_ui}.zip -Destination ./${var.swagger_ui}",
      "Set-Location c:/temp/${var.archive_name}/installers",
      "./Install-SwaggerUI.ps1",
      "Add-Content -Path C:/inetpub/Ed-Fi/SwaggerUI/wwwroot/index.js -Value (Get-Content -Path c:/temp/${var.archive_name}/installers/swagger_index.js)"
    ]
  }

  provisioner "comment" {
    comment     = "Installing Admin App"
    ui          = true
    bubble_text = false
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.password}"
    elevated_user     = "${var.user_name}"
    inline            = [
      "$ErrorActionPreference = 'Stop'",
      "Set-Location c:/temp",
      "Expand-Archive ./${var.admin_app}.zip -Destination ./${var.admin_app}",
      "Set-Location c:/temp/${var.archive_name}/installers",
      "./Install-AdminApp.ps1"
    ]
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.password}"
    elevated_user     = "${var.user_name}"
    inline            = [
      "$ErrorActionPreference = 'Stop'",
      "Remove-item c:/temp/* -Recurse -Force",
      "Optimize-Volume -DriveLetter C"
    ]
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.password}"
    elevated_user     = "${var.user_name}"
    inline            = [
      "$ErrorActionPreference = 'Stop'",
      "Write-Host (\"Web Api => https://{0}/WebApi\" -f [Environment]::MachineName)",
      "Write-Host (\"Admin App => https://{0}/AdminApp\" -f [Environment]::MachineName)",
      "Write-Host (\"SwaggerUI => https://{0}/SwaggerUI\" -f [Environment]::MachineName)"
    ]
  }
}
