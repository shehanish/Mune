//
//  DropDown.swift
//  Mend
//
//  Created by Shehani Hansika on 06.05.26.
//

import SwiftUI

struct DropDownView: View {
    let title: String
    let prompt: String
    let options: [String]
    
    @State private var isExpanded = false
    @Binding var selection: String?
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.black) 
                .opacity(0.8)
                .padding(.horizontal, 20)
            VStack{
                HStack{
                    Text(selection ?? prompt)
                        
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.subheadline)
                        .foregroundStyle(Color.sageGreen)
                        .rotationEffect(.degrees(isExpanded ? -180 : 0))
                }
                .frame(height: 40)
                .background(.ultraThinMaterial)
                .padding(.horizontal)
                .onTapGesture{
                    withAnimation(.snappy) { isExpanded.toggle() }
                    
                    
                }
                if isExpanded {
                    VStack{
                        ForEach(options, id: \.self) { option in
                            HStack{
                                Text(option)
                                    .foregroundStyle(selection == option ? Color.primary : .gray)
                                
                                
                                Spacer()
                                
                                if selection == option {
                                    Image(systemName: "checkmark")
                                        .font(.subheadline)
                                }
                            }
                            .frame(height: 40)
                            .padding(.horizontal)
                            .onTapGesture {
                                withAnimation(.snappy) {
                                    selection = option
                                    isExpanded.toggle()
                                    
                                }
                            }
                        }
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .primary.opacity(0.2), radius: 4)
            .padding(.horizontal)
            
        }
    }
}

#Preview {
    DropDownView(title: "Expected Period", prompt: "30 Days", options: ["30 Days", "60 Days", "90 Days", "Custom"], selection: .constant("60 Days"))
}
