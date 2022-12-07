# DelegateHooker
Hook delegate methods

Only two steps

1. Create your own AppDelegate
<img width="888" alt="image" src="https://user-images.githubusercontent.com/63203414/206097018-69fbb248-5155-4df7-abef-81117cf5e46e.png">

2. Start hooking your own methods
<img width="735" alt="image" src="https://user-images.githubusercontent.com/63203414/206097096-e126c14f-df51-4499-8bb5-ef95d9a86b64.png">

At any point you can hook your own method if the method already exists in the original appdelegate.
If not this tool will automatically add your method before the delegate loads. If the delegate loads it'll give you a friendly message.
