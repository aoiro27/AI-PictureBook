import { GoogleGenAI, Modality } from "@google/genai";
import * as fs from "node:fs";

async function main() {

    console.log(process.env.GOOGLE_API_KEY);
  const ai = new GoogleGenAI({
    apiKey: process.env.GOOGLE_API_KEY
  });

  const contents = "Please draw the following picture for a picture book:A 5-year-old boy named Shiki and 1-year-old girl named Shiro shiki and shiro is brother and their mother getting on a white bus with the number 17 to go to school.";

  // Set responseModalities to include "Image" so the model can generate  an image
  const response = await ai.models.generateContent({
    model: "gemini-2.0-flash-preview-image-generation",
    contents: contents,
    config: {
      responseModalities: [Modality.TEXT, Modality.IMAGE],
    },
  });
  for (const part of response.candidates[0].content.parts) {
    // Based on the part type, either show the text or save the image
    if (part.text) {
      console.log(part.text);
    } else if (part.inlineData) {
      const imageData = part.inlineData.data;
      const buffer = Buffer.from(imageData, "base64");
      fs.writeFileSync("gemini-native-image.png", buffer);
      console.log("Image saved as gemini-native-image.png");
    }
  }
}

main();