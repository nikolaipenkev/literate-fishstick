document.addEventListener("DOMContentLoaded", function() {
    // Initialize GridStack with 100px cell height and 10px vertical margin
    const grid = GridStack.init({
        cellHeight: 100,
        verticalMargin: 10,
        animate: true
    });

    // Reset layout functionality
    document.getElementById("resetButton").addEventListener("click", function() {
        localStorage.removeItem("grid-stack-layout");
        location.reload();
    });

    // Load saved layout if it exists
    const savedLayout = localStorage.getItem("grid-stack-layout");
    if (savedLayout) {
        grid.load(JSON.parse(savedLayout));
    }


    // Helper: Create a gauge chart (doughnut) for gauge-style metrics.
    function createGaugeChart(canvasId, value, maxValue, color) {
        if (!document.getElementById(canvasId)) return;  // Prevent errors

        const ctx = document.getElementById(canvasId).getContext("2d");
        new Chart(ctx, {
            type: "doughnut",
            data: {
                labels: ["Value", "Remaining"],
                datasets: [{
                    data: [value, Math.max(maxValue - value, 0)],
                    backgroundColor: [color, "#2c3e50"]
                }]
            },
            options: {
                cutout: "75%",
                plugins: {
                    legend: { display: false },
                    tooltip: { enabled: true }
                },
                maintainAspectRatio: false,
                responsive: true
            }
        });
    }


    // Helper: Create a horizontal bar chart.
    function createBarChart(canvasId, label, value, color) {
        const ctx = document.getElementById(canvasId).getContext("2d");
        new Chart(ctx, {
            type: "bar",
            data: {
                labels: [label],
                datasets: [{
                    data: [value],
                    backgroundColor: color
                }]
            },
            options: {
                indexAxis: 'y',
                scales: { x: { beginAtZero: true } },
                plugins: {
                    legend: { display: false },
                    tooltip: { enabled: false }
                },
                maintainAspectRatio: false,
                responsive: true
            }
        });
    }

    // Helper: Create a pie chart.
    function createPieChart(canvasId, values, colors) {
        const ctx = document.getElementById(canvasId).getContext("2d");
        new Chart(ctx, {
            type: "pie",
            data: {
                labels: ["Yes", "No"],
                datasets: [{
                    data: values,
                    backgroundColor: colors
                }]
            },
            options: {
                plugins: {
                    legend: { display: false },
                    tooltip: { enabled: false }
                },
                maintainAspectRatio: false,
                responsive: true
            }
        });
    }

    // Create charts using the aggregated stats injected via ERB.
    // The values are inserted as strings from the ERB, so we parse them.
    const avgTitle    = parseFloat("<%= aggregated_stats['Avg Title Length'] %>");
    const avgMeta     = parseFloat("<%= aggregated_stats['Avg Meta Desc Length'] %>");
    const missingAlt  = parseFloat("<%= aggregated_stats['Missing ALT (%)'] %>");
    const avgWord     = parseFloat("<%= aggregated_stats['Avg Word Count'] %>");
    const avgLoadTime = parseFloat("<%= aggregated_stats['Avg Load Time (s)'] %>");
    const avgPageSize = parseFloat("<%= aggregated_stats['Avg Page Size (KB)'] %>");
    const httpsUsage  = parseFloat("<%= aggregated_stats['HTTPS Usage (%)'] %>");
    const gaPresence  = parseFloat("<%= aggregated_stats['GA Presence'] %>");
    const gtmPresence = parseFloat("<%= aggregated_stats['GTM Presence'] %>");
    const totalUrls   = parseFloat("<%= aggregated_stats['Total URLs'] %>");

    // Create gauge charts:
    createGaugeChart("titleLengthChart", avgTitle, 100, "#36a2eb");
    createGaugeChart("metaDescChart", avgMeta, 160, "#ec0d3a");
    createGaugeChart("missingAltChart", missingAlt, 100, "#ffce56");
    createGaugeChart("pageSizeChart", avgPageSize, 5000, "#8e24aa");

    // Create bar charts:
    createBarChart("wordCountChart", "Words", avgWord, "#4bc0c0");
    createBarChart("loadTimeChart", "Load Time", avgLoadTime, "#ffce56");

    // Create pie chart for HTTPS usage:
    createPieChart("httpsChart", [httpsUsage, 100 - httpsUsage], ["#66bb6a", "#e0e0e0"]);

    // Create doughnut charts for GA and GTM presence:
    createGaugeChart("gaChart", gaPresence, totalUrls, "#36a2eb");
    createGaugeChart("gtmChart", gtmPresence, totalUrls, "#ff4081");
});
