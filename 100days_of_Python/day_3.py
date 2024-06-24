# learning: day3 :  CONTROL FLOW AND LOGICAL OPERATION
print("Welcome to the rollercoaster!")

height = int(input("What is you height in cm?"))

if height >= 120:
    print("You can ride the rollercoaster!")
    age = int(input("What is your age?"))
    if age <= 12:
        bill =  5
        print("Child tickets are $5.")
    elif age <= 18:
        bill = 7 
        print("Youth tickets are $7.")
    else: 
        bill = 12
        print("Aldult tickets are $12.")

    want_photo = input("Do you want a photo taken? Y or N. ")
    if want_photo == "Y":
        bill += 3
    
    print(f"Your final bill is {bill}")

else:
    print("Sorry, you have to grow taller before you can ride")



# final project of day 3 

print("Welcome to Treasure Island. Your mission is to find the treasure.")

first_step = input("Left or Right?")

if first_step.lower() == 'right':
    print("Game Over.")

elif first_step.lower() == 'left':
    second_step = input("Swim or wait? ")

    if second_step.lower() == 'swim':
        print("Game Over.")
    
    elif second_step.lower() == 'wait':
        third_step = input("Which color? Blue, Red or Yellow")

        if third_step.lower() == 'red' or third_step.lower() == 'blue':
            print("Game Over.")
        elif third_step.lower() == 'yellow':
            print("You win!")