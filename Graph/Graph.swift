//
//  Graph.swift
//  Graph
//
//  Created by Maxim Macari on 19/10/2020.
//

import WidgetKit
import SwiftUI

//First create Model for widget data...

struct Model: TimelineEntry{
    
    var date: Date
    var widgetData: [JSONModel]
    
}

//Create model for JSON data

struct JSONModel: Decodable, Hashable{
    
    var date: CGFloat
    var units: Int
    
}

//Create Provider to provide data for widget

struct Provider: TimelineProvider {
    
    func getSnapshot(in context: Context, completion: @escaping (Model) -> Void) {
        
        //Initial snapshot
        
        //or loading type content
        
        let loadingData = Model(date: Date(), widgetData: Array(repeating: JSONModel(date: 0, units: 0), count: 6))
        
        completion(loadingData)
        
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Model>) -> Void) {
        
        //parsing json data and displaying
        getData { (modelData) in
            
            let date = Date()
            
            
            let data = Model(date: date, widgetData: modelData)
            
            //Creating Timeline
            
            //reloading data every 15 imns
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: date)
            
            if let nextUpdate = nextUpdate {
                let timeline = Timeline(entries: [data], policy: .after(nextUpdate))
                
                completion(timeline)
            }
        }
    }
    
    func placeholder(in context: Context) -> Model {
        Model(date: Date(), widgetData: Array(repeating: JSONModel(date: 0, units: 0), count: 6))
    }
    
}

//Creating view for widget
struct WidgetView: View {
    
    var data: Model
    let colors: [Color] = [Color.red, Color.yellow, Color.purple, Color.green, Color.blue, Color.pink]
    
    var body: some View{
        
        VStack(alignment: .leading, spacing: 15){
            
            HStack(alignment: .center) {
                Spacer()
                
                Text("Units sold")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding([.top, .horizontal])
                    .frame( alignment: .center)
                
                Spacer()
            }
            
            Divider()
            
            HStack(spacing: 15){
                ForEach(data.widgetData, id: \.self){ value in
                    
                    if value.units == 0 && value.date == 0 {
                        
                        //data is loading
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.gray)
                        
                        
                    }else {
                        //data view
                        VStack(spacing: 15){
                            Text("\(value.units)")
                                .fontWeight(.bold)
                            //Graph
                            
                            GeometryReader { geo in
                                VStack{
                                    
                                    Spacer(minLength: 0)
                                    
                                    
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(colors.randomElement()!)
                                        .frame(height: getHeight(value: CGFloat(value.units), height: geo.frame(in: .global).height))
                                }
                            }
                            //date
                            Text("\(getData(value: value.date))")
                                .font(.caption2)
                            
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    func getHeight(value: CGFloat, height: CGFloat) -> CGFloat{
        
        let max = data.widgetData.max { (first, second) -> Bool in
            
            if first.units > second.units{
                return false
            }else{
                return true
            }
            
            
        }
        
        if let max = max {
            let percent = value / CGFloat(max.units)
            return percent * height
        }else{
            return 0
        }
    }
    
    func getData(value: CGFloat) -> String {
        let format = DateFormatter()
        
        format.dateFormat = "MMM dd"
        
        //since its in millisenconds
        let date = Date(timeIntervalSince1970: Double(value) / 1000.0)
        
        return format.string(from: date)
    }
}

//Widget Configuration
@main
struct MainWidget: Widget {
    
    var body: some WidgetConfiguration {
        
        StaticConfiguration(kind: "any Idetifier", provider: Provider()) { data in
            
            WidgetView(data: data)
            
        }
        //you can use anything
        .description(Text("Daily Status"))
        .configurationDisplayName(Text("Daily updates"))
        .supportedFamilies([.systemLarge])
        
        
    }
}



// ataching completion handler to send back data
func getData(completion: @escaping ([JSONModel]) -> ()){
    
    let url = "https://canvasjs.com/data/gallery/javascript/daily-sales-data.json"
    let urlComponents = URLComponents(string: url)
    
    let session = URLSession(configuration: .default)
    
    //proper unwrap
    if let url = urlComponents?.url {
        session.dataTask(with: url) { (data, res, err) in
            
            if err != nil {
                if let err = err as Error? {
                    print(err.localizedDescription)
                }
                return
            }
            
            if let data = data{
                do{
                    let jsonData = try JSONDecoder().decode([JSONModel].self, from: data)
                    
                    completion(jsonData)
                }catch{
                    print(error.localizedDescription)
                    
                }
            }
            
        }
        .resume()
    }
}


