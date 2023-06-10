
// Classe Curso

import SpriteKit


enum CursoType: Int, Printable {
    
    case Unknown = 0, Dotnet, Java, Php, Python, Discite, Swift
    
    // Retorna o nome do arquivo
    // de imagem do sprite no atlas
    var spriteName: String {
        let spriteNames = [
            "DotNet",
            "Java",
            "Php",
            "Python",
            "Discite",
            "Swift"]
        
        return spriteNames[rawValue - 1]
    }
    
    // Retorna nome do arquivo
    // de imagem do sprite iluminado no atlas
    var highlightedSpriteName: String {
        return spriteName + "-Highlighted"
    }
    
    // Funcao para criar um tipo de curso aleatorio
    // sempre que um novo curso é criado
    static func random() -> CursoType {
        return CursoType(rawValue: Int(arc4random_uniform(6)) + 1)!
    }
    
    var description: String {
        return spriteName
    }
    
}

class Curso: Printable, Hashable {
    
    var row: Int
    var column: Int
    let cursoType: CursoType
    var sprite: SKSpriteNode?
    
    init(column: Int, row: Int, cursoType: CursoType) {
        self.column = column
        self.row = row
        self.cursoType = cursoType
    }
    
    var description: String {
        return "type:\(cursoType) square:(\(column),\(row))"
    }
    
    // Funcao que retorna um valor hash unico para
    // identificar cada objeto curso
    var hashValue: Int {
        return row*10 + column
    }
    
}

func ==(lhs: Curso, rhs: Curso) -> Bool {
    return lhs.column == rhs.column && lhs.row == rhs.row
}
