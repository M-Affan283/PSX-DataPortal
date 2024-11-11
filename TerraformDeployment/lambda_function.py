from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import pdfplumber
from mangum import Mangum

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Set to ["*"] to allow all origins for the Lambda function
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Function to parse the PDF
def parse_pdf_table(pdf_path):
    rows = []
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            page_data = page.extract_words()
            page_data.sort(key=lambda x: (x['top'], x['x0']))

            current_row = []
            current_top = page_data[0]['top'] if page_data else None

            for item in page_data:
                if abs(item['top'] - current_top) > 5:
                    rows.append(current_row)
                    current_row = []
                    current_top = item['top']
                current_row.append(item['text'])

            if current_row:
                rows.append(current_row)

    company_names = []
    turnover, prv_rate, open_rate, highest, lowest, last_rate, diff = [], [], [], [], [], [], []
    detected_technology = False
    for row in rows:
        if detected_technology and len(row) > 3:
            diff.append(row[-1])
            last_rate.append(row[-2])
            lowest.append(row[-3])
            highest.append(row[-4])
            open_rate.append(row[-5])
            prv_rate.append(row[-6])
            turnover.append(row[-7])
            company_names.append(' '.join(row[1:-7]))
        if row == ['***FERTILIZER***']:
            detected_technology = False
        if row == ['***TECHNOLOGY', '&', 'COMMUNICATION***']:
            detected_technology = True

    Technology_section = []
    for j in range(len(company_names)):
        Technology_section.append([company_names[j], turnover[j], prv_rate[j], open_rate[j], highest[j], lowest[j], last_rate[j], diff[j]])

    return Technology_section

@app.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    with open("/tmp/temp.pdf", "wb") as temp_file:  # /tmp is writable in Lambda
        content = await file.read()
        temp_file.write(content)
    headings = ["Name", "Turnover", "Prev Rate", "Open Rate", "Highest Rate", "Lowest Rate", "Last Rate", "Difference"]
    rows = parse_pdf_table("/tmp/temp.pdf")
    rows.insert(0, headings)
    return JSONResponse(content={"headings": headings, "rows": rows})

handler = Mangum(app)

# Zip using: 
# zip -r lambda_function.zip lambda_function.py
# and then terraform init, validate plan, apply :)

