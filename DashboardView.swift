import SwiftUI
import UniformTypeIdentifiers

struct DashboardView: View {
    @StateObject private var viewModel = ScraperViewModel()
    @State private var selectedCategory = "Restaurants"
    @State private var location = "Toronto, ON"
    @State private var isExporting = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Configuration Panel
            VStack(alignment: .leading, spacing: 12) {
                Text("Data Collection Settings")
                    .font(.headline)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Business Category")
                        TextField("e.g., Restaurants", text: $selectedCategory)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Location")
                        TextField("e.g., Vancouver, BC", text: $location)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                HStack {
                    Text("Request Delay:")
                    Slider(value: $viewModel.config.requestDelay, in: 1.0...10.0, step: 0.5)
                    Text("\(viewModel.config.requestDelay, specifier: "%.1f")s")
                        .frame(width: 40)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // Controls
            HStack(spacing: 15) {
                Button("Start Collection") {
                    viewModel.startScraping(category: selectedCategory, location: location)
                }
                .disabled(viewModel.isRunning)
                .buttonStyle(.borderedProminent)
                
                Button("Pause") {
                    viewModel.pauseScraping()
                }
                .disabled(!viewModel.isRunning || viewModel.isPaused)
                
                Button("Resume") {
                    viewModel.resumeScraping()
                }
                .disabled(!viewModel.isPaused)
                
                Button("Stop") {
                    viewModel.stopScraping()
                }
                .disabled(!viewModel.isRunning)
                .buttonStyle(.bordered)
                .tint(.red)
                
                Spacer()
                
                Button("Export Data") {
                    isExporting = true
                }
                .disabled(viewModel.listings.isEmpty)
                .fileExporter(isPresented: $isExporting,
                            document: DataExporter.exportToCSV(viewModel.listings),
                            contentType: .commaSeparatedText,
                            defaultFilename: "business_data_\(Date().formatted(date: .numeric, time: .omitted))") { result in
                    if case .success = result {
                        viewModel.log("Data exported successfully")
                    }
                }
            }
            
            // Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress")
                    Spacer()
                    Text("\(viewModel.collectedCount) records collected")
                }
                .font(.subheadline)
                
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(LinearProgressViewStyle())
                
                Text(viewModel.statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            
            // Data Preview
            VStack(alignment: .leading, spacing: 10) {
                Text("Collected Data (\(viewModel.listings.count) items)")
                    .font(.headline)
                
                List(viewModel.listings.prefix(10)) { listing in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(listing.name)
                            .font(.subheadline).bold()
                        Text("\(listing.category) • \(listing.city)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 200)
            }
            
            // Log Console
            VStack(alignment: .leading, spacing: 8) {
                Text("Activity Log")
                    .font(.headline)
                ScrollView {
                    Text(viewModel.logMessages)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 100)
                .padding(8)
                .background(Color.black.opacity(0.05))
                .cornerRadius(6)
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 800, minHeight: 700)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}