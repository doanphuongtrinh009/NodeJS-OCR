import sharp from 'sharp';

export const preprocessImage = async (buffer: Buffer): Promise<Buffer> => {
    try {
        // Enhance image for OCR: Grayscale, Increase Contrast, Resize if too small
        // Deskew is harder with just sharp, requires analysis. 
        // We will do basic enhancement.
        
        const image = sharp(buffer);
        const metadata = await image.metadata();
        
        let pipeline = image
            .grayscale()
            .normalize() // contrast stretch
            .sharpen();

        // If width is too small, upscale
        if (metadata.width && metadata.width < 1000) {
            pipeline = pipeline.resize({ width: 2000 });
        }

        // Binarize (thresholding) can be good for OCR but sometimes risky if lighting is uneven.
        // sharp.threshold() might be too aggressive. normalize() is safer.

        return await pipeline.toBuffer();
    } catch (error) {
        console.error("Preprocessing error:", error);
        return buffer; // Return original if fail
    }
};
