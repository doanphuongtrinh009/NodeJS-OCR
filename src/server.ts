import express from 'express';
import cors from 'cors';
import { config } from './config';
import ocrRoutes from './routes/ocr.route';

const app = express();

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Routes
app.use(express.static('public'));
app.use('/ocr', ocrRoutes);

app.listen(config.port, () => {
    console.log(`Server running on port ${config.port}`);
});
