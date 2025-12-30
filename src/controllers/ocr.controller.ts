import { Request, Response } from 'express';
import { processInvoice, processText, processVoice, processUrl } from '../services/ocr.service';
import { OcrResponse } from '../types/invoice';

export class OcrController {
    // Process uploaded file (image/PDF)
    static async processInvoice(req: Request, res: Response): Promise<void> {
        try {
            if (!req.file) {
                res.status(400).json({ status: 'error', message: 'No file uploaded' });
                return;
            }

            const { buffer, mimetype } = req.file;
            
            // Get engine from query parameter, default to 'gemini'
            const engine = (req.query.engine as string)?.toLowerCase();
            if (engine && engine !== 'gemini' && engine !== 'gpt') {
                res.status(400).json({ 
                    status: 'error', 
                    message: 'Invalid engine. Use "gemini" or "gpt"' 
                });
                return;
            }

            // Get model from query parameter (optional)
            const model = req.query.model as string | undefined;

            const selectedEngine = (engine as 'gemini' | 'gpt') || 'gemini';
            
            // Process the file
            const result = await processInvoice(buffer, mimetype, selectedEngine, model);

            const response: OcrResponse = {
                status: 'success',
                json: result.json || undefined,
                text_ocr: result.text,
                confidence: result.confidence,
                engine_used: result.engine_used,
                model_used: result.model_used,
                processing_time_ms: result.processing_time_ms
            };

            res.json(response);

        } catch (error: any) {
            console.error(error);
            res.status(500).json({ 
                status: 'error', 
                message: error.message || 'Internal Server Error' 
            });
        }
    }

    // Process text input directly
    static async processTextInput(req: Request, res: Response): Promise<void> {
        try {
            const { text, engine, model } = req.body;
            
            if (!text || typeof text !== 'string') {
                res.status(400).json({ 
                    status: 'error', 
                    message: 'Text input is required' 
                });
                return;
            }

            const selectedEngine = (engine as 'gemini' | 'gpt') || 'gemini';
            const result = await processText(text, selectedEngine, model);

            const response: OcrResponse = {
                status: 'success',
                json: result.json || undefined,
                text_ocr: result.text,
                confidence: result.confidence,
                engine_used: result.engine_used,
                model_used: result.model_used,
                processing_time_ms: result.processing_time_ms
            };

            res.json(response);

        } catch (error: any) {
            console.error(error);
            res.status(500).json({ 
                status: 'error', 
                message: error.message || 'Internal Server Error' 
            });
        }
    }

    // Process voice input (audio file)
    static async processVoiceInput(req: Request, res: Response): Promise<void> {
        try {
            if (!req.file) {
                res.status(400).json({ status: 'error', message: 'No audio file uploaded' });
                return;
            }

            const { buffer, mimetype } = req.file;
            const engine = (req.query.engine as string)?.toLowerCase() || 'gemini';
            const model = req.query.model as string | undefined;

            const selectedEngine = (engine as 'gemini' | 'gpt') || 'gemini';
            const result = await processVoice(buffer, mimetype, selectedEngine, model);

            const response: OcrResponse = {
                status: 'success',
                json: result.json || undefined,
                text_ocr: result.text,
                confidence: result.confidence,
                engine_used: result.engine_used,
                model_used: result.model_used,
                processing_time_ms: result.processing_time_ms
            };

            res.json(response);

        } catch (error: any) {
            console.error(error);
            res.status(500).json({ 
                status: 'error', 
                message: error.message || 'Internal Server Error' 
            });
        }
    }

    // Process URL (fetch image from URL)
    static async processUrlInput(req: Request, res: Response): Promise<void> {
        try {
            const { url, engine, model } = req.body;
            
            if (!url || typeof url !== 'string') {
                res.status(400).json({ 
                    status: 'error', 
                    message: 'URL is required' 
                });
                return;
            }

            const selectedEngine = (engine as 'gemini' | 'gpt') || 'gemini';
            const result = await processUrl(url, selectedEngine, model);

            const response: OcrResponse = {
                status: 'success',
                json: result.json || undefined,
                text_ocr: result.text,
                confidence: result.confidence,
                engine_used: result.engine_used,
                model_used: result.model_used,
                processing_time_ms: result.processing_time_ms
            };

            res.json(response);

        } catch (error: any) {
            console.error(error);
            res.status(500).json({ 
                status: 'error', 
                message: error.message || 'Internal Server Error' 
            });
        }
    }
}
