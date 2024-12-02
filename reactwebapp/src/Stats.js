import React, { useState, useEffect, useCallback, useRef, useMemo } from "react";
import { Link } from "react-router-dom";
import {Chart as ChartJS, CategoryScale, LinearScale, RadialLinearScale, BarElement, LineElement, PointElement, Title, Tooltip, Legend, ArcElement, TimeScale} from "chart.js";
import { Line } from "react-chartjs-2";
import "./Stats.css";

ChartJS.register(CategoryScale, LinearScale, RadialLinearScale, BarElement, LineElement, PointElement, Title, Tooltip, Legend, ArcElement, TimeScale
);

const FASTAPI_API = process.env.REACT_APP_FASTAPI;
// const FASTAPI_API = "localhost:8000";

function Stats() {
    const [timeSeriesData, setTimeSeriesData] = useState({});
    const [isLoading, setIsLoading] = useState(false);
    const dataFetchedRef = useRef(false);

    const graphColors = useMemo(() => ["rgba(255, 99, 132, 0.5)", "rgba(54, 162, 235, 0.5)", "rgba(255, 206, 86, 0.5)", "rgba(75, 192, 192, 0.5)", "rgba(153, 102, 255, 0.5)", "rgba(255, 159, 64, 0.5)", "rgba(199, 199, 199, 0.5)"], []);

    // Function to process time series data for each parameter
    const processTimeSeriesData = useCallback((data) => {
        const parameters = ["turnover", "prev_rate", "open_rate", "highest_rate", "lowest_rate", "last_rate", "difference"];
        const companies = [...new Set(data.map((item) => item.company_name))]; // Get unique company names

        const processedData = parameters.reduce((result, param) => {
            const datasets = companies.map((company, index) => {
                const companyData = data
                    .filter((item) => item.company_name === company)
                    .sort((a, b) => new Date(a.date) - new Date(b.date)); // Sort by date
                const values = companyData.map((item) => item[param]);

                return {
                    label: company,
                    data: values,
                    fill: false,
                    borderColor: graphColors[index % graphColors.length], // Cycle through colors
                    tension: 0.1,
                };
            });

            result[param] = {
                labels: [...new Set(data.map((item) => item.date))].sort((a, b) => new Date(a) - new Date(b)), // Unique sorted dates
                datasets,
            };

            return result;
        }, {});

        setTimeSeriesData(processedData);
    }, [graphColors]);

    useEffect(() => {
        if (dataFetchedRef.current) return;
        dataFetchedRef.current = true;

        const fetchData = async () => {
            try {
                setIsLoading(true);
                const response = await fetch(`http://${FASTAPI_API}/getData`);
                if (response.ok) {
                    const data = await response.json();
                    processTimeSeriesData(data.data);
                } else {
                    console.error("Failed to fetch data.");
                }
            } catch (error) {
                console.error("Error:", error);
            } finally {
                setIsLoading(false);
            }
        };

        fetchData();
    }, [processTimeSeriesData]);

    return (
        <div className="stats-container">
            <h1>Company Data Analysis</h1>
            <nav className="nav-bar">
                <Link to="/" className="nav-link">Home</Link>
                <Link to="/stats" className="nav-link">Stats</Link>
                <Link to="/chatbot" className="nav-link">AI Chatbot</Link>
            </nav>
            {isLoading ? (
                <p>Loading data...</p>
            ) : (
                <>
                    {Object.entries(timeSeriesData).map(([param, data], index) => (
                        <div key={index} className="chart-section">
                            <h2>{param.toUpperCase()} Over Time</h2>
                            <Line
                                data={data}
                                options={{
                                    responsive: true,
                                    plugins: {
                                        legend: { position: "top" },
                                        title: {
                                            display: true,
                                            text: `${param.toUpperCase()} Progression for All Companies`,
                                        },
                                    },
                                    scales: {
                                        x: {
                                            type: "category",
                                            title: {
                                                display: true,
                                                text: "Dates",
                                            },
                                        },
                                        y: {
                                            title: {
                                                display: true,
                                                text: param,
                                            },
                                        },
                                    },
                                }}
                            />
                        </div>
                    ))}
                </>
            )}
        </div>
    );
}

export default Stats;
