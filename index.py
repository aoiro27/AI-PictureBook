# main.py

import vertexai
from vertexai.preview.vision_models import ImageGenerationModel

# プロジェクトIDとリージョンを設定
project_id = ""  # ←ご自身のGCPプロジェクトIDに置き換えてください
location = "us-central1"

# Vertex AIの初期化
vertexai.init(project=project_id, location=location)

# Imagen 3 モデルのロード
generation_model = ImageGenerationModel.from_pretrained("imagen-3.0-generate-001")

# 生成したい画像のプロンプト
prompt = """
Shiki, a 5-year-old boy, takes the number 17 bus to go to school.
"""

# 画像生成
image = generation_model.generate_images(
    prompt=prompt,
    number_of_images=1,
    aspect_ratio="1:1",
    safety_filter_level="block_some",
    person_generation="allow_all",
    add_watermark=True,  # 透かしを追加
)

# 画像を保存
image[0].save("output.png")
print("画像をoutput.pngとして保存しました。")
