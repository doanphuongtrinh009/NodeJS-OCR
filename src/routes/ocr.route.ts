import { Router } from 'express';
import multer from 'multer';
import { OcrController } from '../controllers/ocr.controller';

const router = Router();

// File upload configuration
const upload = multer({ 
    storage: multer.memoryStorage(),
    limits: { fileSize: 50 * 1024 * 1024 } // 50MB for audio/video
});

// ============================================
// OCR INVOICE ROUTES
// ============================================

/**
 * POST /ocr/invoice
 * Process image or PDF file upload
 * @body file - Image (jpg, png) or PDF file
 * @query engine - 'gemini' or 'gpt'
 * @query model - specific model name
 */
router.post('/invoice', upload.single('file'), OcrController.processInvoice);

/**
 * POST /ocr/text
 * Process text input directly (copy-pasted invoice text)
 * @body text - Invoice text content
 * @body engine - 'gemini' or 'gpt'
 * @body model - specific model name
 */
router.post('/text', OcrController.processTextInput);

/**
 * POST /ocr/voice
 * Process voice/audio file (speech-to-text then OCR)
 * @body file - Audio file (mp3, wav, m4a, webm)
 * @query engine - 'gemini' or 'gpt'
 * @query model - specific model name
 */
router.post('/voice', upload.single('file'), OcrController.processVoiceInput);

/**
 * POST /ocr/url
 * Process image from URL
 * @body url - URL to image
 * @body engine - 'gemini' or 'gpt'
 * @body model - specific model name
 */
router.post('/url', OcrController.processUrlInput);

export default router;
