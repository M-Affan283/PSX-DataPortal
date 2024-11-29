import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { Chart as ChartJS, CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend } from "chart.js";
import { Bar } from "react-chartjs-2";
import "./App.css"; // Add a CSS file for styling
// import Stats from "./Stats";

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend);

const LAMBDA_API = "https://cdxwmevp87.execute-api.us-east-1.amazonaws.com"
const FASTAPI_API = "fastapi-alb-390416424.us-east-1.elb.amazonaws.com"

function App() {
    const [file, setFile] = useState(null);
    const [chartData, setChartData] = useState(null);
    const [isLoading, setIsLoading] = useState(false);

    // Handle file input change
    const handleFileChange = (e) => {
        setFile(e.target.files[0]);
    };

    // Handle file upload and parse response
    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!file) return;

        try {
            setIsLoading(true);

            // Read the file as Base64
            const reader = new FileReader();
            reader.onload = async () => {
                const fileContentBase64 = reader.result.split(",")[1]; // Extract base64 part
                const payload = {
                    file_name: file.name,
                    file_content: fileContentBase64,
                };

                // Send file name and content to the lambda function to store in S3 and fastapi to parse and store in database
                const response = await fetch(LAMBDA_API, {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                    },
                    body: JSON.stringify(payload),
                });

                if (response.ok) {
                    alert("File uploaded successfully!");
                } else {
                    console.error("Failed to upload file.");
                }
            };

            reader.onerror = (error) => {
                console.error("Error reading file:", error);
            };

            reader.readAsDataURL(file); // Read file as Base64
        } catch (error) {
            console.error("Error:", error);
        } finally {
            setIsLoading(false);
        }
    };

    // Process data into Chart.js format
    const processChartData = (data) => {
        const labels = data.map((item) => item.company_name);
        const turnovers = data.map((item) => item.turnover);
        const differences = data.map((item) => item.difference);

        setChartData({
            labels,
            datasets: [
                {
                    label: "Turnover",
                    data: turnovers,
                    backgroundColor: "rgba(75, 192, 192, 0.5)",
                    borderColor: "rgba(75, 192, 192, 1)",
                    borderWidth: 1,
                },
                {
                    label: "Difference",
                    data: differences,
                    backgroundColor: "rgba(255, 99, 132, 0.5)",
                    borderColor: "rgba(255, 99, 132, 1)",
                    borderWidth: 1,
                },
            ],
        });
    };

    useEffect(() => {

        // Fetch data for chart
        const fetchDataForGraph = async () => {
            try {
                setIsLoading(true);
                const response = await fetch(`http://${FASTAPI_API}/getData`);
                if (response.ok) {
                    const data = await response.json();
                    console.log(data);
                    processChartData(data.data);
                } else {
                    console.error("Failed to fetch data.");
                }
            } catch (error) {
                console.error("Error:", error);
            } finally {
                setIsLoading(false);
            }
        };

        fetchDataForGraph();
    }, []);

    return (
        <div className="app-container">
            <h1>Company Data Dashboard</h1>
            <nav className="nav-bar">
                <Link to="/" className="nav-link">Home</Link>
                <Link to="/stats" className="nav-link">Stats</Link>
            </nav>

            {/* File Upload Section */}
            <div className="upload-section">
                <h2>Upload PDF</h2>
                <form onSubmit={handleSubmit}>
                    <input type="file" onChange={handleFileChange} accept="application/pdf" />
                    <button type="submit" disabled={isLoading}>
                        {isLoading ? "Uploading..." : "Upload"}
                    </button>
                </form>
            </div>

            {/* Graph Section */}
            <div className="chart-section">
                <h2>Company Performance Graph</h2>
                {chartData ? (
                    <Bar
                        data={chartData}
                        options={{
                            responsive: true,
                            plugins: {
                                legend: {
                                    position: "top",
                                },
                                title: {
                                    display: true,
                                    text: "Company Turnover and Differences",
                                },
                            },
                        }}
                    />
                ) : (
                    <p>Loading chart data...</p>
                )}
            </div>
        </div>
    );
}

export default App;
