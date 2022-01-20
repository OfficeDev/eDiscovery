# Steps for login using eDiscovery Admin Credentials

<b>Steps for login using eDiscovery Admin(Method 1):</b>

- <b>Step by Global Admin:</b>  Connect to Mg-Graph using Global admin credentials using the following command in powershell window:

         Connect-MgGraph -Scopes "eDiscovery.ReadWrite.All, Group.ReadWrite.All"
         
Accept this and grant permissions to all the users.
         
![GAAccept](https://user-images.githubusercontent.com/69503744/150277137-77ab7464-3900-4de4-87aa-b494056c6189.png)

- <b>Step by eDisc Admin:</b> 

Try to login using eDiscovery Admin first on this screen.

Select your role as eDiscovery Admin.

Select ‘Y’ for "Is eDiscovery ReadWrite permissions already granted to eDiscovery Admin?"


![2Y](https://user-images.githubusercontent.com/69503744/150278047-84c7a2df-eb23-43b2-9c73-d15ed6462695.png)






<b>Steps for login using eDiscovery Admin(Method 2):</b>


- <b>Step by Global Admin:</b>  Login to AzureAD using Global admin credentials.

Go to Enterprise Applications > User Settings

Find the below option “Admin consent request”

Set this “Users can request admin consent to apps they are unable to consent to” to “Yes”.

_Wait for few hours. It may take 6-12 hours to take effect._

![eDisc1](https://user-images.githubusercontent.com/69503744/150069590-e8479afc-716f-4777-8b86-ac5d7a48c4ff.png)


<b>WARNING:</b> This step will allow users to request admin consent for any enterprise app. Access can be granted only by the administrator. You can switch on/off (select yes/no for this feature) as per your need.



- <b>Step by eDisc Admin:</b>  Try to login using eDiscovery Admin first on this screen.

Select your role as eDiscovery Admin.

Select ‘N’ for "Is eDiscovery ReadWrite permissions already granted to eDiscovery Admin?"

 
![2N](https://user-images.githubusercontent.com/69503744/150278075-822965f9-4881-4062-8cab-104838c03218.png)

 

   Now as you don’t have global admin rights you can ask for approval from admin just by filling the justification here.

![eDisc4](https://user-images.githubusercontent.com/69503744/150069722-089cd451-3227-4d2c-9661-68411ba63249.png)



- <b>Step by Global Admin:</b> Login to AzureAD portal using admin credentials and approve the request.

You can find the request here in

Enterprise Applications > Admin consent requests > All(preview) 

![eDisc5](https://user-images.githubusercontent.com/69503744/150069759-b1164e77-e334-4020-929a-182b417c766a.png)


Here select the request you want to approve and click on Review permissions and consent and approve using global admin credentials.

![eDisc6](https://user-images.githubusercontent.com/69503744/150069776-d5dff2fc-4301-45e4-9e7a-bf4b9936cd07.png)

approve using global admin credentials.

![eDisc7](https://user-images.githubusercontent.com/69503744/150069788-d49cec26-3795-433f-9c22-1c966dab9a71.png)



- <b>Step by eDisc Admin:</b> Try to login using eDiscovery Admin first on this screen.

Here select your role as “Global Admin”
 
Now login again using eDiscovery Admin credentials. You will be able to login now.
![GA0](https://user-images.githubusercontent.com/69503744/150277837-5a859c89-819f-48f8-858d-4fa10db90a52.png)


 


