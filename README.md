# DelegateHooker
Hook delegate methods

Only two steps

1. Create your own AppDelegate
<img width="888" alt="image" src="https://user-images.githubusercontent.com/63203414/206097018-69fbb248-5155-4df7-abef-81117cf5e46e.png">

Or your own SceneDelegate
<img width="705" alt="image" src="https://user-images.githubusercontent.com/63203414/206628484-fd9d4e49-a13b-4906-b8d8-0cf5205c59dd.png">

2. Start hooking your own methods
<img width="1310" alt="image" src="https://user-images.githubusercontent.com/63203414/206628408-664277d1-73fe-4e2b-908e-dc781905c90e.png">

At any point you can hook your own method if the method already exists in the original appdelegate.
If not this tool will automatically add your method before the delegate loads. If the delegate loads it'll give you a friendly message.
