# main.py

import os
import vertexai
from vertexai.preview.vision_models import ImageGenerationModel

# サービスアカウントキーのパスを指定
service_account_path = "/path/to/your/service-account.json"  # ←ここを変更

# 環境変数をスクリプト内で設定
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = service_account_path

# プロジェクトIDとリージョンを設定
project_id = "YOUR_PROJECT_ID"  # ←ここを変更
location = "us-central1"

# Vertex AIの初期化
vertexai.init(project=project_id, location=location)

# Imagen 3 モデルのロード
generation_model = ImageGenerationModel.from_pretrained("imagen-3.0-generate-001")

# 生成したい画像のプロンプト
prompt = """
A photorealistic image of a cookbook laying on a wooden kitchen table, the cover facing forward featuring a smiling family sitting at a similar table, soft overhead lighting illuminating the scene, the cookbook is the main focus of the image.
"""

# 画像生成
image = generation_model.generate_images(
    prompt=prompt,
    number_of_images=1,
    aspect_ratio="1:1",
    safety_filter_level="block_some",
    person_generation="allow_all",
    add_watermark=True,
)

# 画像を保存
image[0].save("output.png")
print("画像をoutput.pngとして保存しました。")
