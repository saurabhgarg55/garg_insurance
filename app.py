import os
import re
from flask import Flask, request, jsonify
from PyPDF2 import PdfReader
from werkzeug.utils import secure_filename
from datetime import datetime

app = Flask(__name__)
UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

def parse_indian_date(date_str):
    """
    Parses a date string with common Indian formats.
    Returns a date string in 'YYYY-MM-DD' format or None if parsing fails.
    """
    if not date_str:
        return None
    for fmt in ('%d-%m-%Y', '%d/%m/%Y', '%d.%m.%Y', '%Y-%m-%d', '%m/%d/%Y'):
        try:
            return datetime.strptime(date_str, fmt).strftime('%Y-%m-%d')
        except ValueError:
            pass
    return None

def extract_policy_info(text):
    """
    Extracts policy information from text using enhanced regex.
    """
    info = {
        "policyholder_name": "",
        "vehicle_number": "",
        "policy_type": "",
        "policy_number": "",
        "insurer_name": "",
        "policy_start_date": "",
        "policy_end_date": "",
        "premium_amount": "",
        "contact_number": "" # Added contact number field
    }

    # Enhanced Regex patterns with more variations
    patterns = {
        "policyholder_name": r"(?:Policyholder|Insured Name|Name|Customer Name|Applicant Name):\s*([A-Za-z\s\.]+)",
        "vehicle_number": r"(?:Vehicle No|Registration No|Chassis No|Engine No|Vehicle Number):\s*([A-Za-z0-9\s]+)", # Added \s for potential spaces
        "policy_type": r"(?:Policy Type|Type of Policy|Insurance Type):\s*([A-Za-z\s]+)",
        "policy_number": r"(?:Policy No|Policy Number|Policy Ref No):\s*([A-Za-z0-9\-\/]+)",
        "insurer_name": r"(?:Insurer|Insurance Company|Issued By):\s*([A-Za-z\s\.&]+)", # Added & for company names like HDFC ERGO
        "policy_start_date": r"(?:Policy Start Date|Effective Date|Date of Commencement|From Date):\s*(\d{1,2}[./-]\d{1,2}[./-]\d{2,4})", # More flexible date regex
        "policy_end_date": r"(?:Policy End Date|Expiry Date|To Date):\s*(\d{1,2}[./-]\d{1,2}[./-]\d{2,4})", # More flexible date regex
        "premium_amount": r"(?:Premium Amount|Total Premium|Amount Payable):\s*(?:Rs\.?|₹|INR|USD|\$)?\s*([\d,\.]+)", # More flexible amount regex
        "contact_number": r"(?:Contact No|Phone|Mobile|Contact Number):\s*(\+?\d[\d\s\-()]{7,})" # Basic contact number pattern
    }

    # Simple keyword-based policy type identification as a fallback or addition
    if not info["policy_type"]:
        if re.search(r'auto policy|motor insurance|vehicle insurance', text, re.IGNORECASE):
            info["policy_type"] = "Auto Policy"
        elif re.search(r'health insurance|medical insurance', text, re.IGNORECASE):
             info["policy_type"] = "Health Insurance Policy"

    for key, pattern in patterns.items():
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            extracted_value = match.group(1).strip()
            # Basic cleaning
            extracted_value = re.sub(r'\s+', ' ', extracted_value).strip() # Replace multiple spaces with single space

            if key in ["policy_start_date", "policy_end_date"]:
                parsed_date = parse_indian_date(extracted_value)
                if parsed_date:
                    info[key] = parsed_date
                else:
                    print(f"Warning: Could not parse date for {key}: {extracted_value}")
            elif key == "premium_amount":
                 # Remove commas and currency symbols for parsing as float
                 cleaned_amount = re.sub(r'[^\d.]', '', extracted_value) # Remove non-digit and non-dot characters except commas
                 cleaned_amount = cleaned_amount.replace(',', '') # Remove commas specifically
                 try:
                     info[key] = str(float(cleaned_amount)) # Store as string representation of float
                 except ValueError:
                      print(f"Warning: Could not parse premium amount: {extracted_value}")
            else:
                info[key] = extracted_value

    # Placeholder for using a list of known insurers (if available in the backend)
    # known_insurers = ["Navi General Insurance Ltd.", "Reliance General Insurance Co. Ltd.", ...]
    # for insurer in known_insurers:
    #     if re.search(re.escape(insurer), text, re.IGNORECASE):
    #         info["insurer_name"] = insurer
    #         break # Stop after finding the first match

    # Add logging for debugging
    print("Extracted Text:
", text[:500] + '...') # Print first 500 characters of text
    print("Extracted Info:", info)

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
            # Iterate through pages and extract text
            for i in range(len(reader.pages)):
                 page = reader.pages[i]
                 text += page.extract_text() + "
"
            
            extracted_data = extract_policy_info(text)
            return jsonify(extracted_data), 200
        except Exception as e:
            # Log the error on the server side
            print(f"Error processing PDF: {str(e)}")
            return jsonify({"error": f"Error processing PDF: {str(e)}"}), 500
        finally:
            # Ensure the file is removed even if an error occurs
            if os.path.exists(filepath):
                os.remove(filepath) # Clean up the uploaded file
    else:
        return jsonify({"error": "Unsupported file type. Please upload a PDF."}), 400

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
