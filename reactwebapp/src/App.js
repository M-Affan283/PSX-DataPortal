import React, { useState } from "react";

function App() {
  const [file, setFile] = useState(null);
  const [rows, setRows] = useState([]);

  const handleFileChange = (e) => {
    setFile(e.target.files[0]);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!file) return;

    const formData = new FormData();
    formData.append("file", file);

    try {
      const response = await fetch("http://localhost:8000/upload", {
        method: "POST",
        body: formData,
      });

      if (response.ok) {
        const data = await response.json();
        setRows(data.rows); // Update rows with the parsed data
      } else {
        console.error("Failed to upload file.");
      }
    } catch (error) {
      console.error("Error:", error);
    }
  };

  return (
    <div style={{ padding: "20px" }}>
      <h2>Upload PDF for Table Parsing</h2>
      <form onSubmit={handleSubmit}>
        <input type="file" onChange={handleFileChange} accept="application/pdf" />
        <button type="submit">Upload</button>
      </form>
      <div>
        <h3>Parsed Rows:</h3>
        {rows.length > 0 ? (
          <ul>
            {rows.map((row, index) => (
              <li key={index}>{row.join(", ")}</li>
            ))}
          </ul>
        ) : (
          <p>No rows parsed yet.</p>
        )}
      </div>
    </div>
  );
}

export default App;
