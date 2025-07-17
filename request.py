import base64
import io
from PIL import Image
import requests
import json

# APIから画像データを取得
response = requests.post('https://ai-picture-488889291017.asia-northeast1.run.app', 
                        json={'prompt': 'Shiki-chan is the big brother of a six-year-old boy.Shiro-chan is his little sister, a one-year-old girl.They are siblings.One day, the two of them found a big pill bug in the garden.“Wow! It’s all curled up!” said Shiro-chan.“This is called a pill bug. It curls up into a ball when it gets scared,” Shiki-chan explained.'})

print("Status Code:", response.status_code)

try:
    data = response.json()
    print("Response format:", data.get('format'))
    
    image_base64 = data.get('image', '')
    print("Base64 length:", len(image_base64))
    print("Base64 starts with:", image_base64[:50])
    print("Base64 ends with:", image_base64[-50:])
    
    # Base64から画像に復元
    image_bytes = base64.b64decode(image_base64)
    print("Decoded bytes length:", len(image_bytes))
    print("First 20 bytes:", [b for b in image_bytes[:20]])
    
    # PNGファイルの場合は89 50 4E 47で始まるはず
    if len(image_bytes) >= 4:
        header = image_bytes[:4]
        print("File header:", [hex(b) for b in header])
        
        if header == b'\x89PNG':
            print("Valid PNG header detected")
        else:
            print("Invalid PNG header - this might not be a valid image")
    
    # 画像として開いてみる
    try:
        image = Image.open(io.BytesIO(image_bytes))
        print("Image opened successfully")
        print("Image size:", image.size)
        print("Image mode:", image.mode)
        image.save('received_image.png')
        print("画像を保存しました")
    except Exception as e:
        print("画像として開けません:", e)
        
except Exception as e:
    print("エラー:", e)