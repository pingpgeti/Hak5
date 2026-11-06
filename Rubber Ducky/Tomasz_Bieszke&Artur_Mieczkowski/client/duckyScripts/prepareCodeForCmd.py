def prepareCode(filePath):
    """
    filePath:   path to the file you want to prapare for cmd injection
    return:     returns a string array with every line of the code
    """
    strings = []
    specialChars = ['^', '&', '|', '>', '<', '(', ')']

    with open(filePath, "r") as f:
        for line in f.readlines():
            wholeString=""
            print(line)

            for a in line:
                if a in specialChars:
                    wholeString+='^'
                wholeString+=a
            strings.append(wholeString)
    
    newFileName = filePath.split(".")[0] + ".txt"
    with open(newFileName, "w") as f:
        for wholeString in strings:
            f.write(wholeString)
    
    return strings
                
            
if __name__ == "__main__":
    for line in prepareCode("oneLiner.c"):
        print(line)