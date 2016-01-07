def hex2volt(hexNumber):
    i=int(hexNumber,16)
    rDivider=2550.0/(10000.0+2550.0)
    ntox=rDivider/3.3*255.0
    xton=1/ntox
    print '{} is {} V'.format(hexNumber,repr(xton*i))

def volt2hex(voltage):
    i=int(voltage,10)
    rDivider=2550.0/(10000.0+2550.0)
    ntox=rDivider/3.3*255.0
    print '{} is {}'.format(voltage,hex(int(ntox*i)))


def main():
    while(1):
        if(raw_input("1 for hex2volt 2 for volt2hex: ")=='1'):
            hex2volt(raw_input("Enter hex number: "))
        else:
            volt2hex(raw_input("Enter a voltage: "))
main()
