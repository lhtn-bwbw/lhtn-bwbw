# filnal test of day2: calculate tip by person with inputs are: total bill, %tip and number of people to split the bill

print("Welcome to the tip calculator!")

bill = float(input("What was the total bill? $ "))

tip= float(input("How much tip would you like to give? 10, 12 or 15?"))

num_people = int(input("How many people to split the bill?"))

result = round((bill + tip/100*bill) / num_people, 2)

result = "{:.2f}".format(result)
print(f"Each person should pay: ${result}")