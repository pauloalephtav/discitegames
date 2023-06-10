struct Swap: Printable, Hashable {
    let cursoA: Curso
    let cursoB: Curso
    
    init(cursoA: Curso, cursoB: Curso) {
        self.cursoA = cursoA
        self.cursoB = cursoB
    }
    
    var hashValue: Int {
        return cursoA.hashValue ^ cursoB.hashValue
    }
    
    var description: String {
    return "swap \(cursoA) with \(cursoB)"
    }
}

func ==(lhs: Swap, rhs: Swap) -> Bool {
    return (lhs.cursoA == rhs.cursoA && lhs.cursoB == rhs.cursoB) ||
            (lhs.cursoB == rhs.cursoA && lhs.cursoA == rhs.cursoB)
}
