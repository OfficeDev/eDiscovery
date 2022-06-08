# eDiscovery Shift 
Core eDiscovery (E3) to Advanced eDiscovery (E5) Migration Tool

## Overview
Today, customers have no direct pathway to migrate their eDiscovery cases from [Core eDiscovery (E3)](https://docs.microsoft.com/en-us/microsoft-365/compliance/get-started-core-ediscovery?view=o365-worldwide) to [Advanced eDiscovery (E5)](https://docs.microsoft.com/en-us/microsoft-365/compliance/overview-ediscovery-20?view=o365-worldwide#subscriptions-and-licensing). 

The eDiscovery Shift tool will mitigate the overhead of a manual case migration by providing customers with an automated migration solution. After migrating existing core eDiscovery (CED) cases into Advanced eDiscovery (AED), customers are able to take advantage of the additional features available in the advanced solution. 

## Objective
At the current time, historical and ongoing eDiscovery cases created in the Core eDiscovery solution are not automatically available in the Advanced eDiscovery solution. The process required to upgrade cases from the Microsoft 365 Core eDiscovery solution into the Advanced eDiscovery solution requires multiple manual interventions. 

The eDiscovery Shift tool provides you with:
- <b>Automation:</b> Case settings, hold policies and searches are copied from the core eDiscovery case into a newly created Advanced eDiscovery case. 
- <b>Minimize case management overhead:</b> eDiscovery Administrators are now able to migrate all ongoing cases from CeD into AeD directly, minimizing overhead of managing multiple eDiscovery solutions. 
- <b>GUI-based tool:</b> Easily use tool GUI to migrate the cases without requirement for technical expertise with PowerShell scripts and/or Microsoft’s Graph API.


### How does eDiscovery Shift work?

1. Creates a new Advanced eDiscovery case.
2. Migrates core eDiscovery case details and holds. 
3. Generate migration status report including any failures.
4. Release the holds from old cases (Coming Soon)
5. Delete old Core eDiscovery cases (Coming Soon)


## Before you begin

### Pre-requisites

#### 1. Licensing & subscription
Before using eDiscovery Shift, ensure that you have appropriate organization subscription and per-user licensing. To access Advanced eDiscovery in the Microsoft 365 Compliance Center, your organization must have one of the following:
- Microsoft 365 E5 or Office 365 E5 subscription
- Microsoft 365 E3 subscription with E5 Compliance add-on
- Microsoft 365 E3 subscription with E5 eDiscovery and Audit add-on
- Microsoft 365 Education A5 or Office 365 Education A5 subscription

If you don't have an existing Microsoft 365 E5 plan and want to try Advanced eDiscovery, you can [add Microsoft 365](https://docs.microsoft.com/en-us/office365/admin/try-or-buy-microsoft-365) to your existing subscription or [sign up for a trial](https://www.microsoft.com/microsoft-365/enterprise) of Microsoft 365 E5.

#### 2. Roles & user permissions 
You must have appropriate role/user permissions to be able to run this tool. There are two ways you may run this tool.

- Using Global Administrator credentials. (You must have _<b>both</b>_ of the following roles)
    - Global Administration
    - eDiscovery Administrator role group 
- Using eDiscovery Administrator credentials. 
    - eDiscovery Administrator role group needed
    - Dependency on Global Admin. 
      Please refer [this guide](https://github.com/OfficeDev/eDiscovery/blob/main/Documents/eDiscoveryAdminUserConfig.md) for more information.

#### 3. PowerShell 
- You must have PowerShell version 5.1 or above to run this tool.
- You must have Exchange Online PowerShell module (You can follow either of the following 2 methods to download the same)
    - Exchange Online PowerShell V2 module that is available via the PowerShell gallery:
        ```powershell 
        Install-Module -Name ExchangeOnlineManagement
        ```
    - Exchange Online PowerShell module (http://aka.ms/exopsmodule)
- You must have Microsoft Graph (Compliance) module (You can follow the following method to download the same)
    - Microsoft Graph (Compliance) module that is available via the PowerShell gallery:
        ```powershell 
        Install-Module -Name "Microsoft.graph.compliance"
        ```


## Migration Instructions

### Installation

- Step 0: [Download](https://github.com/OfficeDev/eDiscovery/archive/refs/heads/main.zip) & extract zip file from this repository.
- Step 1: Open PowerShell in administrator mode.
- Step 2: Navigate to the location from *Step 0* where you have downloaded the files.
    ```powershell 
    cd C:/Downloads/eDiscovery-Shift-main
    ```
- Step 3: Load the eDiscovery PowerShell module.
    ```powershell 
    . .\RuneDiscoveryShift.ps1
    ```
 You are now ready to start migrating your Core eDiscovery cases to Advanced eDiscovery!

### Migrate cases

1. Run the following cmdlet in your PowerShell window to launch the application.
```powershell
Start-Migration
```

2. Login to Exchange Online and Security & Compliance Centre with your credentials (_must have eDiscovery Administrator role_)
    
   ![exclogin](https://user-images.githubusercontent.com/69503744/148892202-56391ea4-d439-4560-b454-907e3c31c31b.png)


3. Login to Microsoft Graph with your credentials (You can login using the following 2 methods)
    - Login using global admin credentials (_must have both Global Administration role and eDiscovery Administrator role group_)
    
    ![GA0](https://user-images.githubusercontent.com/69503744/150276693-09df0763-610f-47ec-acbd-043f15cf7b01.png)

    
    - Login using eDisc admin credentials (_must have eDiscovery Administrator role group_)

    NOTE:  If you want to login using eDiscovery Admin, please follow the steps mentioned in  [this guide](https://github.com/OfficeDev/eDiscovery/blob/main/Documents/eDiscoveryAdminUserConfig.md). This will have dependency on Global Admin.

    
4. Click *Get Started* button once the application launches.
![image](https://user-images.githubusercontent.com/67892508/148191465-84d5e5ee-e25f-4eff-8734-631978d62573.png)

5. Select the Core eDiscovery cases you want to migrate to Advanced eDiscovery. Then click *Migrate Selected* or *Migrate All* button.
![image](https://user-images.githubusercontent.com/67892508/148191576-7763bfb9-194a-4015-8038-377815f5b7c6.png)

6. Review your case selection and click the *Start Migration* button.
![image](https://user-images.githubusercontent.com/67892508/148191770-5ad72341-6fcf-40c7-8c53-6739e4563b58.png)

7. Be patient! Wait for PowerShell scripts to complete execution. Once the PowerShell script has completed execution:
    - Look at the final migration status report
    - Visit [Compliance Center](compliance.microsoft.com) and check your new cases.

8. \[OPTIONAL\] If you are satisfied with your new Advanced eDiscovery case, you can go ahead and delete/close the corresponding Core eDiscovery case.


## Provide Feedback & Report Bugs
To report errors & any feature requests with us by opening a new issue in this Github repository. Alternatively, you can reach out to us at cxe-help@microsoft.com or via your CXE / Fasttrack / Microsoft partner to share your feedback and suggestions.


## Telemetry Notice
### Data Collection
This software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. If you wish to turn off telemetry, please reach out to us and we will provide you with a separate version of tool with telemetry turned off. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft's privacy statement. Our privacy statement is located at https://go.microsoft.com/fwlink/?LinkID=824704. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
