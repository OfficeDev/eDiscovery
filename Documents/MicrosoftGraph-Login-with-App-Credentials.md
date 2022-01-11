# Login to Microsoft Graph PowerShell SDK using app only authentication
_(For non-global admin users)_

1. Login to ‘https://portal.azure.com’ using global admin credentials.

2. Go to app registrations. 
![image](https://user-images.githubusercontent.com/67892508/148884074-638491e9-217c-4f7f-89df-cea5232b37d9.png)


3. Select new registaration.
![image](https://user-images.githubusercontent.com/67892508/148884097-a93bec2d-7c87-442d-887e-941972d19e72.png)
 

4. Set the name and supported account type as shown below: 
![image](https://user-images.githubusercontent.com/67892508/148884223-db6cf750-837a-4b82-b299-407bfa516219.png)

5. Leave Redirect URI blank and click on Register.
![image](https://user-images.githubusercontent.com/67892508/148884253-77d2d5a5-b1d7-4adc-86ad-544163142b80.png)

6. Under Certificates & secrets, you have to upload certificate. You can either upload an existing X.509 certificate or create a new one and then upload it. 
![image](https://user-images.githubusercontent.com/67892508/148884262-bbdea0fb-58af-496e-b829-5d7d7e2ad659.png)

## Creating new X.509 certificate using PowerShell:

7. Run the following command:
```powershell
$Cert = New-SelfSignedCertificate  -CertStoreLocation
"Cert:\CurrentUser\My" -FriendlyName "MicrosoftGraphSDK"
-Subject "Test Cert for Microsoft Graph SDK"
```
```powershell
Get-ChildItem "Cert:\CurrentUser\My\$($Cert.thumbprint)"
```
![image](https://user-images.githubusercontent.com/67892508/148884302-d966f727-7dce-4c73-b267-1c12b3538ff3.png)
![image](https://user-images.githubusercontent.com/67892508/148884333-0e87eb4b-ddbb-4324-94eb-996960f18865.png)


8. After creating the certificate, we export it to a .cer file.
Run the following command to export the .cer file to the specified FilePath.

```powershell
Get-ChildItem "Cert:\CurrentUser\My\$($Cert.thumbprint)"
| Export-Certificate -FilePath C:\WINDOWS\system32\MicrosoftGraphSDK.cer 
```

![image](https://user-images.githubusercontent.com/67892508/148884348-a6bda43e-aad1-4e64-9abe-9dc831b6d0a4.png)

9. Upload the certificate created.
![image](https://user-images.githubusercontent.com/67892508/148884362-90664578-65c6-418e-b1a0-2d45a68ed46d.png)
![image](https://user-images.githubusercontent.com/67892508/148884378-ba4ebc1f-0565-4367-abbb-25ac3e62ea14.png)

10. Store the thumbprint of the certificate. 
![image](https://user-images.githubusercontent.com/67892508/148884393-294c13e3-de7d-45df-8709-6224e84f0f4c.png)

11. Under API permissions, click on Add a permission
![image](https://user-images.githubusercontent.com/67892508/148884407-b8dd6be6-0d12-48e2-bcf5-48589af71543.png)

12. Click on Microsoft Graph under Microsoft APIs 
![image](https://user-images.githubusercontent.com/67892508/148884427-a70cc1ef-a1c6-4d41-9dce-02588f096b2b.png)

13. Click on Application Permissions. 
![image](https://user-images.githubusercontent.com/67892508/148884440-fc0f1a8e-7d07-4085-8eef-e173a4f950d2.png)

14. Add eDiscovery.ReadWrite.All permisssion
![image](https://user-images.githubusercontent.com/67892508/148884462-c4013550-67fc-430a-b012-15026c027909.png)

15. Grant Admin Consent for Contoso 
![image](https://user-images.githubusercontent.com/67892508/148884477-f4d03a51-a93e-4ade-9db6-4e70d1b755f8.png)

16. Under overview tab, you can find client id and tenant id.
![image](https://user-images.githubusercontent.com/67892508/148884493-12283742-7e5c-4763-ab96-57eb854936cb.png)

17. Use client id, tenant id and certificate thumbprint (from step 10) to login to the tool/mggraph. Share these values with the eDiscovery Admin and other users who want to use the tool.

18. Run this command to connect to the mggraph.

```powershell
Connect-MgGraph -ClientID <ClientID>
-TenantId < TenantId > 
-CertificateThumbprint < CertificateThumbprint >
```

19. Login to eDiscovery Shift App using app credentials as shown below: 
![image](https://user-images.githubusercontent.com/67892508/148884520-e5d32f08-4bcb-4572-a840-3feed81ae712.png)
