from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import os
import pdfplumber
import databases
import sqlalchemy
from sqlalchemy import Table, Column, String, Float, MetaData, UniqueConstraint
from dotenv import load_dotenv
from pydantic import BaseModel
import datetime
import base64

# Load environment variables from .env.local
load_dotenv(".env.local")

# Database URL from environment variable
DATABASE_URL = os.getenv("NEONDB")
database = databases.Database(DATABASE_URL)

class FileUploadPayload(BaseModel):
    file_name: str
    file_content: str  # Base64-encoded content

# SQLAlchemy Metadata
metadata = MetaData()

# Define the 'companies' table with composite keys
companies = Table(
    "companies",
    metadata,
    Column("company_name", String, primary_key=True),
    Column("date", String, primary_key=True),
    Column("turnover", Float),
    Column("prev_rate", Float),
    Column("open_rate", Float),
    Column("highest_rate", Float),
    Column("lowest_rate", Float),
    Column("last_rate", Float),
    Column("difference", Float),
    UniqueConstraint("company_name", "date", name="company_date_uc")
)

# Create the database engine and bind metadata
try:
    engine = sqlalchemy.create_engine(DATABASE_URL)
    metadata.create_all(engine)
except Exception as e:
    print("[SERVER ERROR] In creating engine, Error: ", e)
    raise ValueError(f"Error creating engine: {e}")

# Initialize FastAPI app
app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # or use ["*"] to allow all origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Connect to Database on Startup
@app.on_event("startup")
async def startup():
    try:
        await database.connect()
        print("[SERVER LOGS] server has started and db is connected")
    except Exception as e:
        print("[SERVER ERROR] In startup function, Error: ", e)
        # raise ValueError(f"Error connecting to database: {e}")

# Disconnect Database on Shutdown
@app.on_event("shutdown")
async def shutdown():
    await database.disconnect()
    print("[SERVER LOGS] server shutdown")

# Function to parse the file name and extract date
def parse_file_date(file_name):
    try:
        # Example format: "closingRates_202401nov"
        print("[SERVER LOGS] In parsing_file_date function, file_name received: ", file_name)
        prefix, raw_date = file_name.split("_")
        # print("raw date is: ", raw_date)
        year = raw_date[:4]
        day = raw_date[4:6]
        month_str = raw_date[6:9].lower()
        month = {
            "jan": "01", "feb": "02", "mar": "03", "apr": "04",
            "may": "05", "jun": "06", "jul": "07", "aug": "08",
            "sep": "09", "oct": "10", "nov": "11", "dec": "12"
        }.get(month_str, "00")  # Default to "00" for invalid months

        if month == "00":
            raise ValueError("Invalid month in file name.")

        # Format as DD-MM-YY
        formatted_date = f"{day}-{month}-{year[2:]}"
        print("[SERVER LOGS] In parsing_file_date function, formatted_date returning: ", formatted_date)
        return formatted_date
    except Exception as e:
        print("[SERVER ERROR] In parsing_file_date function, Error: ", e)
        raise ValueError(f"Error parsing date from file name: {file_name}. Error: {e}")

# Function to parse PDF data
def parse_pdf_table(pdf_path):
    try:
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
        print("[SERVER LOGS] In parse_pdf_table function, Returning tech data: ", Technology_section)
        return Technology_section
    except Exception as e:
        print("[SERVER ERROR] In parse_pdf_table function, Error: ", e)
        raise ValueError(f"Error parsing data from file path: {pdf_path}. Error: {e}")

# Endpoint to upload and parse PDF, then insert data into the database
@app.post("/upload")
async def upload_file(payload: FileUploadPayload = None):
    print("[SERVER LOGS] upload to db route invoked")
    try: 

        if payload is None:
            raise HTTPException(status_code=400, detail="Invalid payload")

        file_name = payload.file_name
        file_content_base64 = payload.file_content
        try:
            # Parse the date from the file name
            date = parse_file_date(file_name)
        except ValueError as e:
            return JSONResponse(content={"error": str(e)}, status_code=400)
        # Decode the Base64 file content
        try:
            file_content = base64.b64decode(file_content_base64)
        except Exception as e:
            raise HTTPException(status_code=400, detail="Invalid Base64 file content")
        # Save the decoded file content to a temporary file
        temp_file_path = "temp.pdf"
        with open(temp_file_path, "wb") as temp_file:
            temp_file.write(file_content)
        # Parse the PDF to extract data
        rows = parse_pdf_table(temp_file_path)
        # Insert each row into the database
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
                date=date,
                turnover=turnover,
                prev_rate=prev_rate,
                open_rate=open_rate,
                highest_rate=highest_rate,
                lowest_rate=lowest_rate,
                last_rate=last_rate,
                difference=difference,
            )
            await database.execute(query)
        print("[SERVER LOGS] upload to db successful")
        return JSONResponse(content={"message": "Data uploaded successfully."})
    except Exception as e:
        print("[SERVER ERROR] In upload route")
        raise ValueError(f"Error while trying to upload file Error: {e}")

# Endpoint to check server health
@app.get("/health")
async def health_check():
    print("[SERVER LOGS] Health check invoked")
    return JSONResponse(content={"message": "Server is healthy"}, status_code=200)

# Root endpoint
@app.get("/")
async def root():
    print("[SERVER LOGS] Root Get Request invoked")
    return JSONResponse(content={"message": "Server is healthy"}, status_code=200)

@app.get("/getData")
async def get_data():
    print("[SERVER LOGS] Data Fetch request invoked")
    try: 
        query = companies.select()
        rows = await database.fetch_all(query)
        data = [
            {
                "company_name": row["company_name"],
                "date": row["date"],
                "turnover": row["turnover"],
                "prev_rate": row["prev_rate"],
                "open_rate": row["open_rate"],
                "highest_rate": row["highest_rate"],
                "lowest_rate": row["lowest_rate"],
                "last_rate": row["last_rate"],
                "difference": row["difference"],
            }
            for row in rows
        ]
        print("[SERVER LOGS] Data Fetch request successful")
        return JSONResponse(content={"data": data}, status_code=200)
    except Exception as e:
        print("[SERVER ERROR] In getData route, Error: ", e)
        raise ValueError(f"Error while trying to get Data from DB Error: {e}")

