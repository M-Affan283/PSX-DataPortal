import pdfplumber

def parse_pdf_table(pdf_path):
    rows = []

    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            page_data = page.extract_words()  # Extract text with positions

            # Sort items by their vertical position first (top to bottom)
            page_data.sort(key=lambda x: (x['top'], x['x0']))

            current_row = []
            current_top = page_data[0]['top'] if page_data else None

            for item in page_data:
                # Check if the item is in the same row based on vertical position
                if abs(item['top'] - current_top) > 5:  # Threshold to detect new row
                    rows.append(current_row)
                    current_row = []
                    current_top = item['top']

                current_row.append(item['text'])

            if current_row:  # Add the last row
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
        # print(row)
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
        Technology_section.append([company_names[j], turnover[j], prv_rate[j], open_rate[j], highest[j], lowest[j], last_rate[j], diff[j] ])


    return Technology_section

# Example usage:
pdf_path = './PSX_21Oct.pdf'
tech = parse_pdf_table(pdf_path)

print(tech)

