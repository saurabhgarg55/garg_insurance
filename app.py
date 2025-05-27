    import os
import re
from flask import Flask, request, jsonify
from PyPDF2 import PdfReader
from werkzeug.utils import secure_filename

app = Flask(__name__)
UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

def extract_policy_info(text):
    """
    Extracts policy information from text using regex.
    This is a simplified AI-like approach.
    """
    info = {
        "policyholder_name": "",
        "vehicle_number": "",
        "policy_type": "",
        "policy_number": "",
        "insurer_name": "",
        "policy_start_date": "",
        "policy_end_date": "",
        "premium_amount": ""
    }

    # Regex patterns (these are examples and might need refinement based on actual document formats)
    patterns = {
        "policyholder_name": r"(?:Policyholder|Insured Name|Name):\s*([A-Za-z\s\.]+)",
        "vehicle_number": r"(?:Vehicle No|Registration No|Chassis No):\s*([A-Za-z0-9]+)",
        "policy_type": r"(?:Policy Type):\s*([A-Za-z\s]+)",
        "policy_number": r"(?:Policy No|Policy Number):\s*([A-Za-z0-9\-\/]+)",
        "insurer_name": r"(?:Insurer|Insurance Company):\s*([A-Za-z\s\.]+)",
        "policy_start_date": r"(?:Policy Start Date|Effective Date):\s*(\d{2}[./-]\d{2}[./-]\d{4})",
        "policy_end_date": r"(?:Policy End Date|Expiry Date):\s*(\d{2}[./-]\d{2}[./-]\d{4})",
        "premium_amount": r"(?:Premium Amount|Total Premium):\s*(?:Rs\.?|₹|\$)?\s*([\d,]+\.?\d{0,2})"
    }

    for key, pattern in patterns.items():
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            info[key] = match.group(1).strip()

    return info

@app.route('/analyze-policy', methods=['POST'])
def analyze_policy():
    if 'file' not in request.files:
        return jsonify({"error": "No file part in the request"}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400
    if file and file.filename.endswith('.pdf'):
        filename = secure_filename(file.filename)
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(filepath)

        try:
            reader = PdfReader(filepath)
            text = ""
            for page in reader.pages:
                text += page.extract_text() + "\n"
            
            extracted_data = extract_policy_info(text)
            return jsonify(extracted_data), 200
        except Exception as e:
            return jsonify({"error": f"Error processing PDF: {str(e)}"}), 500
        finally:
            os.remove(filepath) # Clean up the uploaded file
    else:
        return jsonify({"error": "Unsupported file type. Please upload a PDF."}), 400

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
