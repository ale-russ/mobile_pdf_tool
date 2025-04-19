import pikepdf
import pdfplumber
import fitz
import os
import boto3
from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.responses import FileResponse
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter
from docx import Document
from PIL import Image
from typing import List

app = FastAPI()

# Temporary directory for file storage
TEMP_DIR = "temp_files"
os.makedirs(TEMP_DIR, exist_ok=True)

# AWS S3 configuration (for online mode)
S3_BUCKET = 'your-s3-bucket-name'
s3_client = boto3.client('s3')

# Helper function to save uplaoded file


async def save_uploaded_file(uploaded_file: UploadFile) -> str:
    file_path = os.path.join(TEMP_DIR, uploaded_file.filename)
    with open(file_path, 'wb') as f:
        content = await uploaded_file.read()
        f.write(content)
    return file_path

# Helper function to upload file to S3 (Online mode)


def upload_to_s3(file_path: str, filename: str):
    s3_client.upload_file(file_path, S3_BUCKET, filename)
    return f'https://{S3_BUCKET}.s3.amazonaws.com/{filename}'

# Merge PDF files


@app.post("/merge")
async def merge_pdfs(files: List[UploadFile] = File(...)):
    if not files:
        raise HTTPException(status_code=400, detail="No files provided")

    output_path = os.path.join(TEMP_DIR, "merged.pdf")
    output_pdf = pikepdf.Pdf.new()

    for file in files:
        file_path = await save_uploaded_file(file)
        with pikepdf.Pdf.open(file_path) as pdf:
            output_pdf.pages.extend(pdf.pages)

    output_pdf.save(output_path)

    # For online mode, upload to s3
    if os.getenv("MODE") == "online":
        s3_url = upload_to_s3(output_path, "merged.pdf")
        return {"message": "PDFs merged successfully", "url": s3_url}

    return FileResponse(output_path, media_type="application/pdf", filename="merged.pdf")

# Split PDF files
@app.post("/split")
async def split_pdf(file: UploadFile = File(...), pages: str = Form("")):
    file_path = await save_uploaded_file(file)
    print(f"page to split: {pages}")
    output_files = []

    with pikepdf.Pdf.open(file_path) as pdf:
        total_pages = len(pdf.pages)
        print(f"total pages of PDF: {total_pages}")

        # Parse split points (e.g., "3,7" means split after page 3 and page 7)
        if not pages:
            # if no pages are provided, return the original PDF as a single File
            raise HTTPException(
                status_code=500, detail="No page for splitting is provided")
        
        print(f"opened PDF: {pages}")
        try:
            # split_indices = sorted([int(p) for p in pages.split(",") if p])
            page_groups = []

            for part in pages.split(","):
                print(f"pages {part}")
                if "-" in part:
                    start, end = map(int, part.split("-"))
                    if start < 1 or end > total_pages or start > end:
                        raise HTTPException(
                            status_code=400, detail=f"Invalid range: {part}. Pages must be between 1 and {total_pages}, and start must be less than end.")
                    page_groups.append(list(range(start, end + 1)))
                else:
                    page_num = int(part)
                    print(f"page_num: {page_num}")
                    if page_num < 1 or page_num > total_pages:
                        raise HTTPException(
                            status_code=400, detail=f"Invalid page: {page_num}. Pages must be between 1 and {total_pages}.")
                    page_groups.append([page_num])

            print(f"Page groups to split: {page_groups}")

            # Create a new PDF for each range
            for group_index, page_list in enumerate(page_groups, 1):
                output_pdf = pikepdf.Pdf.new()
                for page_num in page_list:
                    output_pdf.pages.append(pdf.pages[page_num - 1])
                output_path = os.path.join(
                    TEMP_DIR, f"split_{group_index}.pdf")
                output_pdf.save(output_path)
                output_files.append(output_path)

        except ValueError:
            raise HTTPException(
                status_code=400, detail="Invalid split point format. Use comma-separated page numbers(e.g '3,7').")

    if os.getenv("MODE") == "online":
        s3_urls = [upload_to_s3(f, os.path.basename(f)) for f in output_files]
        return {"message": "PDF Split", "urls": s3_urls}

    return {"message": "PDF Split", "files": output_files}


# Convert to Word
@app.post("/convert-to-word")
async def convert_to_word(file: UploadFile = File(...)):
    file_path = await save_uploaded_file(file)
    output_path = os.path.join(TEMP_DIR, "output.docx")
    doc = Document()

    with pdfplumber.open(file_path) as pdf:
        for page in pdf.pages:
            text = page.extract_text()
            if text:
                doc.add_paragraph(text)

    doc.save(output_path)

    if os.getenv("MODE") == "online":
        s3_url = upload_to_s3(output_path, "output.docx")
        return {"message": "Converted to Word successfully", "url": s3_url}

    return FileResponse(output_path, medai_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document", filename="output.docx")


# Extract Pages (Similar to split but returns specific pages)
@app.post("/extract-pages")
async def extract_pages(file: UploadFile = File(...), pages: str = "1"):
    # return await split_pdf(file, pages)
    file_path = await save_uploaded_file(file)
    output_files = []

    with pikepdf.Pdf.open(file_path) as pdf:
        total_pages = len(pdf.pages)

        # Parse the pages to extract (eg. "1,3,5")
        try:
            page_list = []
            for part in pages.split(","):
                if "-" in part:
                    start, end = map(int, part.split("-"))
                    page_list.extend(range(start, end + 1))
                else:
                    page_list.append(int(part))
            page_list = sorted(set(page_list))  # Remove duplicates and sort
        except ValueError:
            raise HTTPException(
                status_code=400, detail="Invalid page range format")

        # Extract each specified page as a separate PDF
        for page_num in page_list:
            if page_num < 1 or page_num > total_pages:
                continue
            output_pdf = pikepdf.Pdf.new()
            output_pdf.pages.append(pdf.pages[page_num - 1])
            output_path = os.path.join(TEMP_DIR, f"page_{page_num}.pdf")
            output_pdf.save(output_path)
            output_files.append(output_path)

    if os.getenv("MODE") == "online":
        s3_url = [upload_to_s3(f, os.path.basename(f)) for f in output_files]
        return {"message": "Pages extracted", "url": s3_url}

    return {"message": "Pages Extracted", "files": output_files}
# Create PDF


@app.post("/create-pdf")
async def create_pdf(text: str = "Sample PDF"):
    output_path = os.path.jion(TEMP_DIR, "created.pdf")
    c = canvas.Canvas(output_path, pagesize=letter)
    c.drawString(100, 750, text)
    c.save()

    if os.getenv("MODE") == "online":
        s3_url = upload_to_s3(output_path, "created.pdf")
        return {"message": "PDF created successfully", "url": s3_url}
    return FileResponse(output_path, media_type="application/pdf", filename="created.pdf")

# Edit PDF (Add text Annotation)


@app.post("/edit-pdf")
async def edit_pdf(file: UploadFile = File(...), text: str = "Annotation", x: int = 100, y: int = 100):
    file_path = await save_uploaded_file(file)
    output_path = os.path.join(TEMP_DIR, "edited.pdf")

    doc = fitz.open(file_path)
    page = doc[0]  # Edit first page
    page.insert_text((x, y), text, fontsize=12, color=(1, 0, 0))  # Red text
    doc.save(output_path)
    doc.close()

    if os.getenv("MODE") == "online":
        s3_url = upload_to_s3(output_path, "edited.pdf")
        return {"message": "PDF edited successfully", "url": s3_url}

    return FileResponse(output_path, media_type="application/pdf", filename="edited.pdf")

# Add Image to PDF


@app.post("/add-image-to-pdf")
async def add_image(file: UploadFile = File(...), image: UploadFile = File(...), page_num: int = 1, x: int = 100, y: int = 100):
    file_path = await save_uploaded_file(file)
    image_path = await save_uploaded_file(image)
    output_path = os.path.join(TEMP_DIR, "image_added.pdf")

    # Convert image to a format the app can handle
    img = Image.open(image_path)
    img.save(image_path, "PNG")

    doc = fitz.open(file_path)
    if page_num < 1 or page_num > len(doc):
        raise HTTPException(status_code=400, detail="Invalid page number")

    page = doc[page_num - 1]
    page.insert_image(rect=fitz.Rect(
        x, y, x+100, y + 100), filename=image_path)
    doc.save(output_path)
    doc.close()

    if os.getenv("MODE") == "online":
        s3_url = upload_to_s3(output_path, "image_added.pdf")
        return {"message": "Image added to PDF successfully", "url": s3_url}

    return FileResponse(output_path, media_type="application/pdf", filename="image_added.pdf")

# Remove Image from PDF (Basid: Remove first image and specified page)


@app.post("/remove-image")
async def remove_image(file: UploadFile = File(...), page_num: int = 1):
    file_path = await save_uploaded_file(file)
    output_path = os.path.join(TEMP_DIR, "image_removed.pdf")

    doc = fitz.open(file_path)
    if page_num < 1 or page_num > len(doc):
        raise HTTPException(status_code=400, detail="Invalid page number")

    page = doc[page_num - 1]
    images = page.get_images(full=True)
    if not images:
        raise HTTPException(
            status_code=400, detail="NO image found on this page")

    # Remove the first image
    page.delete_image(images[0][0])
    doc.save(output_path)
    doc.close()

    if os.getenv("MODE") == "online":
        s3_url = upload_to_s3(output_path, "image_removed.pdf")
        return {"message": "Image removed from PDF successfully", "url": s3_url}

    return FileResponse(output_path, media_type="application/pdf", filename="image_removed.pdf")

# Extra Text


@app.post("/extract-text")
async def extract_text(file: UploadFile = File(...)):
    file_path = await save_uploaded_file(file)
    extracted_text = []

    with pdfplumber.open(file_path) as pdf:
        for page in pdf.pages:
            text = page.extract_text()
            if text:
                extracted_text.append(text)

    return {"message": "Text extracted successfully", "text": "\n".join(extracted_text)}

# Extract Images


@app.post("/extract-images")
async def extract_images(file: UploadFile = File(...)):
    file_path = await save_uploaded_file(file)
    output_files = []

    doc = fitz.open(file_path)
    for page_num in range(len(doc)):
        page = doc[page_num]
        images = page.get_images(full=True)
        for img_index, img in enumerate(images):
            xref = img[0]
            base_image = doc.extract_image(xref)
            image_bytes = base_image["image"]
            output_path = os.path.join(
                TEMP_DIR, f"image_{page_num + 1}_{img_index}.png")
            with open(output_path, "wb") as f:
                f.write(image_bytes)
            output_files.append(output_path)

    doc.close()

    if os.getenv("MODE") == "online":
        s3_urls = [upload_to_s3(file, os.path.basename(file))
                   for file in output_files]
        return {"message": "Images extracted successfully", "urls": s3_urls}

    return {"message": "Images extracted successfully", "files": output_files}

# Encrypt PDF


@app.post("/encrypt")
async def encrypt_pdf(file: UploadFile = File(...), password: str = "password"):
    file_path = await save_uploaded_file(file)
    output_path = os.path.join(TEMP_DIR, "encrypted.pdf")

    with pikepdf.Pdf.open(file_path) as pdf:
        pdf.save(output_path, encryption=pikepdf.Encryption(user=password))

    if os.getenv("MODE") == "online":
        s3_url = upload_to_s3(output_path, "encrypted.pdf")
        return {"message": "PDF encrypted", "url": s3_url}

    return FileResponse(output_path, media_type="application/pdf", filename="encrypted.pdf")
