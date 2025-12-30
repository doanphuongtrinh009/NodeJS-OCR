import dotenv from 'dotenv';

dotenv.config();

export const config = {
  port: process.env.PORT || 3000,
  openaiApiKey: process.env.OPENAI_API_KEY || '',
  geminiApiKey: process.env.GEMINI_API_KEY || '',
  ocrEngine: process.env.OCR_ENGINE || 'tesseract', // 'tesseract' or 'paddle' (not impl)
};
