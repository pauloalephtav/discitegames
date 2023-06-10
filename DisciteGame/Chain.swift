

class Chain: Hashable, Printable {
    // Cursos que fazem parte da cadeia
    var cursos = [Curso]()
    
    enum ChainType: Printable {
        case Horizontal
        case Vertical
        
        
        var description: String {
            switch self {
            case .Horizontal: return "Horizontal"
            case .Vertical: return "Vertical"
            }
        }
    }
    
    // Qualquer tipo de cadeia.
    var chainType: ChainType
    
    // Pontuacao que a cadeia gerou.
    var score = 0
    
    init(chainType: ChainType) {
        self.chainType = chainType
    }
    
    func addCurso(curso: Curso) {
        cursos.append(curso)
    }
    
    func firstCurso() -> Curso {
        return cursos[0]
    }
    
    func lastCurso() -> Curso{
        return cursos[cursos.count - 1]
    }
    
    var length: Int {
        return cursos.count
    }
    
    var description: String {
        return "type:\(chainType) cursos:\(cursos)"
    }
    
    var hashValue: Int {
        return reduce(cursos, 0) { $0.hashValue ^ $1.hashValue }
    }
}

func ==(lhs: Chain, rhs: Chain) -> Bool {
    return lhs.cursos == rhs.cursos
}
