name = 'reverse'
def f(input):
    output = []
    for i in range(len(input) - 1, -1, -1):
        output.append(input[i])

    return output
