import React, { useState, useEffect, useCallback, useRef, useMemo } from "react";
import { Link } from "react-router-dom";
import {
    Chart as ChartJS,
    CategoryScale,
    LinearScale,
    RadialLinearScale,
    BarElement,
    LineElement,
    PointElement,
    Title,
    Tooltip,
    Legend,
    ArcElement,
    TimeScale,
} from "chart.js";
import { Bar, Line, PolarArea } from "react-chartjs-2";
import "./Stats.css";

ChartJS.register(
    CategoryScale,
    LinearScale,
    RadialLinearScale,
    BarElement,
    LineElement,
    PointElement,
    Title,
    Tooltip,
    Legend,
    ArcElement,
    TimeScale 
);

const FASTAPI_API = "fastapi-alb-390416424.us-east-1.elb.amazonaws.com"

function Stats() {
    const [chartData, setChartData] = useState([]);
    const [timeSeriesData, setTimeSeriesData] = useState(null);
    const [isLoading, setIsLoading] = useState(false);
    const dataFetchedRef = useRef(false);

    const graphTypes = {
        turnover: Bar,
        prev_rate: Line,
        open_rate: Line,
        highest_rate: Line,
        lowest_rate: Line,
        last_rate: Line,
        difference: PolarArea,
    };

    const graphColors = useMemo(() => ({
        turnover: "rgba(75, 192, 192, 0.5)",
        prev_rate: "rgba(54, 162, 235, 0.5)",
        open_rate: "rgba(153, 102, 255, 0.5)",
        highest_rate: "rgba(255, 206, 86, 0.5)",
        lowest_rate: "rgba(255, 99, 132, 0.5)",
        last_rate: "rgba(75, 192, 192, 0.5)",
        difference: ["rgba(255, 99, 132, 0.5)", "rgba(54, 162, 235, 0.5)"],
    }), []);

    // Function to process general chart data
    const processChartData = useCallback((data) => {
        const parameters = ["turnover", "prev_rate", "open_rate", "highest_rate", "lowest_rate", "last_rate", "difference"];
        const processedData = parameters.map((param) => {
            const labels = data.map((item) => item.company_name);
            const values = data.map((item) => item[param]);

            const color = Array.isArray(graphColors[param]) ? graphColors[param][0] : graphColors[param];
            const borderColor = typeof color === "string" ? color.replace("0.5", "1") : "rgba(0, 0, 0, 1)";

            return {
                parameter: param,
                labels,
                datasets: [
                    {
                        label: param,
                        data: values,
                        backgroundColor: color,
                        borderColor,
                        borderWidth: 1,
                    },
                ],
            };
        });
        setChartData(processedData);
    }, [graphColors]);

    const processTimeSeriesData = useCallback((data) => {
        const companies = [...new Set(data.map((item) => item.company_name))]; 
        const datasets = companies.map((company, index) => {
            const companyData = data
                .filter((item) => item.company_name === company)
                .sort((a, b) => new Date(a.date) - new Date(b.date));
            // const dates = companyData.map((item) => item.date);
            const highestRates = companyData.map((item) => item.highest_rate);

            return {
                label: company,
                data: highestRates,
                fill: false,
                borderColor: `hsl(${(index * 360) / companies.length}, 70%, 50%)`, 
                tension: 0.1,
            };
        });

        setTimeSeriesData({
            labels: [...new Set(data.map((item) => item.date))].sort((a, b) => new Date(a) - new Date(b)), 
            datasets,
        });
    }, []);

    useEffect(() => {
        if (dataFetchedRef.current) return;
        dataFetchedRef.current = true;

        const fetchData = async () => {
            try {
                setIsLoading(true);
                const response = await fetch(`http://${FASTAPI_API}/getData`);
                if (response.ok) {
                    const data = await response.json();
                    processChartData(data.data);
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
    }, [processChartData, processTimeSeriesData]);

    return (
        <div className="stats-container">
            <nav className="nav-bar">
                <Link to="/" className="nav-link">Home</Link>
                <Link to="/stats" className="nav-link">Stats</Link>
            </nav>
            <h1>Company Data Analysis</h1>
            {isLoading ? (
                <p>Loading data...</p>
            ) : (
                <>
                    {chartData.map((chart, index) => {
                        const GraphComponent = graphTypes[chart.parameter];
                        return (
                            <div key={index} className="chart-section">
                                <h2>{chart.parameter.toUpperCase()} Graph</h2>
                                <GraphComponent
                                    data={chart}
                                    options={{
                                        responsive: true,
                                        plugins: {
                                            legend: { position: "top" },
                                            title: {
                                                display: true,
                                                text: `Graph for ${chart.parameter}`,
                                            },
                                        },
                                    }}
                                />
                            </div>
                        );
                    })}
                    {timeSeriesData && (
                        <div className="chart-section">
                            <h2>Daily High Rates by Company</h2>
                            <Line
                                data={timeSeriesData}
                                options={{
                                    responsive: true,
                                    plugins: {
                                        legend: { position: "top" },
                                        title: {
                                            display: true,
                                            text: "Time Series: Daily High Rates by Company",
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
                                                text: "Highest Rates",
                                            },
                                        },
                                    },
                                }}
                            />
                        </div>
                    )}
                </>
            )}
        </div>
    );
}

export default Stats;
