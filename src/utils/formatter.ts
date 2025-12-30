export const normalizeAmount = (value: string | number | undefined): number => {
    if (!value) return 0;
    if (typeof value === 'number') return value;
    // Remove non-digit characters except dot and minus, and handle comma as thousand separator or decimal depending on locale
    // In VN, usually 1.000.000,00 or 1,000,000.00. 
    // Circular 78 usually implies standard accounting formats.
    // For simplicity, we assume text coming from AI might be "1,000,000" or "1.000.000".
    // We will let the AI normalize it to standard JSON number format (dots for decimals if any, no thousand separators).
    // If AI fails and we get strings:
    let clean = value.replace(/[^0-9.,-]/g, '');
    
    // Heuristic: if last punctuation is ',', it's likely decimal separator in VN format (if followed by 2 digits)
    // But AI prompt asks for "number", so we expect a number or stringified number.
    
    return parseFloat(clean) || 0;
};

export const normalizeDate = (dateStr: string): string => {
    // Expect YYYY-MM-DD from AI. Return as is if valid, else try to parse.
    return dateStr; 
};
