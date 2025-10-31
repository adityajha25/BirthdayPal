import SwiftUI

struct ContentView: View {
    var body: some View {
        LandingPage()
    }
}

struct LandingPage: View {
    @State var contactsVM = // add VM for contacts here
    var body: some View{
        GeometryReader { geometry in
            VStack{
                HStack{
                    Text("BirthdayPal").foregroundStyle(.white).font(.title)
                    Spacer()
                }.padding(.horizontal)
                HStack{
                    Text("Never miss a special day").foregroundStyle(.gray)
                    Spacer()
                }.padding(.horizontal)
                HStack{
                    Text("Upcoming").foregroundStyle(.white).font(.title3)
                    Spacer()
                  Text("\(contactsVM.thisMonth) this month")
                }.padding()
                
                ForEach(contactsVM.contacts) {contact in
                    NavigationLink(destination: editView()) {
                        BdayCard(contact: contact, screenwidth: geometry.size.width, screenheight: geometry.size.height)
                    }
                }
            }.frame(width: geometry.size.width, height: geometry.size.height).background(.black)
        }
    }
}

struct BdayCard: View {
    var contact : contact
    var screenwidth : CGFloat
    var screenheight: CGFloat
    var body: some View {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                    .frame(height: screenheight * 0.16)
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.clear)
                            .stroke(.white)
                            .frame(width: screenwidth * 0.125, height: screenwidth * 0.125)
                        VStack {
                            Text("\(contact.date.formattedMonthDay().split(separator: " ")[0])")
                                .foregroundStyle(.white)
                                .padding(.top, 1)
                            Text("\(contact.date.formattedMonthDay().split(separator: " ")[1])")
                                .foregroundStyle(.white)
                                .padding(.bottom, 1)
                        }
                    }.frame(width: screenwidth * 0.15, height: screenwidth * 0.15)
                        .padding(.trailing, 4)
                    VStack(alignment: .leading) {
                        Text(contact.name)
                            .bold()
                            .font(.system(size: 25))
                            .foregroundStyle(.white)
                        Text(contact.dateTo)
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    if contact.gender == "male" {
                        Text("👨").font(.title)
                    } else if contact.gender == "female" {
                        Text("👧").font(.title)
                    }
                }.padding(10)
            }
    }
}

struct editView : View {
    var body: some View {
        
    }
}
