from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import pdfplumber
import databases
import sqlalchemy
from sqlalchemy import Table, Column, String, Float, MetaData, UniqueConstraint
from dotenv import load_dotenv

# Load environment variables from .env.local
load_dotenv(".env.local")

# Database URL from environment variable
DATABASE_URL = os.getenv("NEONDB")
database = databases.Database(DATABASE_URL)

# SQLAlchemy Metadata
metadata = MetaData()

# Define the 'companies' table with composite keys
companies = Table(
    "companies",
    metadata,
    Column("company_name", String, primary_key=True),
    Column("file_name", String, primary_key=True),
    Column("turnover", Float),
    Column("prev_rate", Float),
    Column("open_rate", Float),
    Column("highest_rate", Float),
    Column("lowest_rate", Float),
    Column("last_rate", Float),
    Column("difference", Float),
    UniqueConstraint("company_name", "file_name", name="company_file_uc")
)

# Create the database engine and bind metadata
engine = sqlalchemy.create_engine(DATABASE_URL)
metadata.create_all(engine)

# Initialize FastAPI app
app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],  # or use ["*"] to allow all origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Connect to Database on Startup
@app.on_event("startup")
async def startup():
    await database.connect()

# Disconnect Database on Shutdown
@app.on_event("shutdown")
async def shutdown():
    await database.disconnect()

# Function to parse PDF data
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
    turnover = []
    prv_rate = []
    open_rate = []
    highest = []
    lowest = []
    last_rate = []
    diff = []
    detected_technology = False
    for row in rows:
        if detected_technology == True and len(row) > 3:
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
        Technology_section.append([
            company_names[j], turnover[j], prv_rate[j], open_rate[j],
            highest[j], lowest[j], last_rate[j], diff[j]
        ])

    return Technology_section

# Endpoint to upload and parse PDF, then insert data into the database
@app.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    file_name = file.filename  # Get the uploaded file name

    # Save the uploaded file temporarily
    with open("temp.pdf", "wb") as temp_file:
        content = await file.read()
        temp_file.write(content)

    # Parse the PDF to get company data
    rows = parse_pdf_table("temp.pdf")
    
    # Insert each row into the companies table with file_name as a composite key
    for row in rows:
        company_name = row[0]
        turnover = float(row[1])
        prev_rate = float(row[2])
        open_rate = float(row[3])
        highest_rate = float(row[4])
        lowest_rate = float(row[5])
        last_rate = float(row[6])
        difference = float(row[7])

        # Construct the insert query
        query = companies.insert().values(
            company_name=company_name,
            file_name=file_name,
            turnover=turnover,
            prev_rate=prev_rate,
            open_rate=open_rate,
            highest_rate=highest_rate,
            lowest_rate=lowest_rate,
            last_rate=last_rate,
            difference=difference,
        )
        await database.execute(query)

    return JSONResponse(content={"message": "Data uploaded successfully."})
