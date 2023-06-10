
// Classe Level
// Preenche os cursos no array

import Foundation

// Array 9x9
let NumColumns = 9
let NumRows = 9

class Level {
    private var cursos = Array2D<Curso>(columns: NumColumns, rows: NumRows)
    private var tiles = Array2D<Tile>(columns: NumColumns, rows: NumRows)
    
    // A lista de swipes que retorna um swap valido. Usado para determinar quando
    // o jogador pode fazer um certo movimento, quando a tela precisa ser misturada,
    // e gerar dicas.
    private var possibleSwaps = Set<Swap>()
    
    // Score label
    var objetivo = 0
    var maxJogadas = 0
    private var comboMultiplica = 0
    
    
    //func shuffeAutomatico() {
    //    if (possibleSwaps.count == 0) {
    //        shuffle()
   //     }
        
    //}
    
    
    // Cria um Level carregado de um arquivo
    init(filename: String) {
        
        if let dictionary = Dictionary<String, AnyObject>.loadJSONFromBundle(filename) {
            
            // O dictionary contem um array chamado "tiles". Este array contem
            // um elemento para cada linha do level. Cada um deste elemento linha
            // se torna tbm un array descrevendo as colunas nesta linha. Se uma coluna
            // é 1, significa que existe um tile nesta posicao, 0 significa que nao existe.
            if let tilesArray: AnyObject = dictionary["tiles"] {
                
                // Loop entre linhas
                for (row, rowArray) in enumerate(tilesArray as! [[Int]]) {
                    
                    // No Sprite Kit (0,0) esta no topo da tela,
                    // entao precisa ler esse arquivo de cima pra baixo.
                    let tileRow = NumRows - row - 1
                    
                    // Loop entre as colunas da linha corrent
                    for (column, value) in enumerate(rowArray) {
                        
                        // Se o valor do Json é 1, cria o objeto tile.
                        if value == 1 {
                            tiles[column, tileRow] = Tile()
                        }
                    }
                }
                
                objetivo = dictionary["targetScore"] as! Int
                maxJogadas = dictionary["moves"] as! Int
            }
        }
        
    }
    
    
    // MARK: Game Setup
    
    // Funcao para embaralhar os cursos
    func shuffle() -> Set<Curso> {
        
        var set: Set<Curso>
        do {
            // Removo os cursos antigos e preenche com os cursos novos
            set = inicializaCursos()
            
            // Na inicializacao de cada level é preciso detectar qual curso o jogador pode
            // mover atualmente. Se o jogador tentar movimentar 2 cursos que nao estao neste set
            // entao o jogo nao pode aceitar como um movimento valido.
            // Tambem informa quando nao existem mais trocas possiveis e mistura altomaticamente.
            detectPossibleSwaps()
            
            //println("Movimentos possiveis: \(possibleSwaps)")
            
            // Se nao existem movimentos possiveis, entao executa novamente ate existir.
        }
        while possibleSwaps.count == 0
        
        return set
        
    }
    
    // Funcao que inicializa a matriz de cursos
    // montando randomicamente os cursos
    private func inicializaCursos() -> Set<Curso> {
        var set = Set<Curso>()
        
        // Faz loop pra montar a matriz
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                // Apenas faz um curso se existe um tile
                if tiles[column, row] != nil {
                    
                    // Pega um tipo de curso aleatoriamente
                    var cursoType: CursoType
                    
                    do {
                        cursoType = CursoType.random()
                    }
                    while (column >= 2 &&
                            cursos[column - 1, row]?.cursoType == cursoType &&
                            cursos[column - 2, row]?.cursoType == cursoType)
                        || (row >= 2 &&
                            cursos[column, row - 1]?.cursoType == cursoType &&
                            cursos[column, row - 2]?.cursoType == cursoType)
                    
                    // Cria um objeto Curso e adiciona na matriz 2D
                    let curso = Curso(column: column, row: row, cursoType: cursoType)
                    cursos[column, row] = curso
                    
                    // Adiciona o objeto na colecao de Cursos (set)
                    set.insert(curso)
                }
            }
        }
        return set
    }

    // MARK: Querying the Level
    
    // Funcao que retorna os cursos
    func cursoAtColumn(column: Int, row: Int) -> Curso? {
        // Uso do assert para verificar se os numeros das colunas
        // estao dentro de um range valido 0-8
        // assert() testa uma condicao.
        // se o teste falhar, o app ira gerar um crash
        // com um log de erro
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        
        return cursos[column, row]
    }
    
    // Funcao que retorna os Tiles
    func tileAtColumn(column: Int, row: Int) -> Tile? {
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        
        return tiles[column, row]
    }
    
    // Determina  se o movimento é possivel
    func isPossibleSwap(swap: Swap) -> Bool {
        return possibleSwaps.contains(swap)
    }
    
    // MARK: Swapping
    
    func performSwap(swap: Swap) {
        let columnA = swap.cursoA.column
        let rowA = swap.cursoA.row
        let columnB = swap.cursoB.column
        let rowB = swap.cursoB.row
        
        cursos[columnA, rowA] = swap.cursoB
        swap.cursoB.column = columnA
        swap.cursoB.row = rowA
        
        cursos[columnB, rowB] = swap.cursoA
        swap.cursoA.column = columnB
        swap.cursoA.row = rowB
    }
    
    
    // MARK: Detecting Swaps
    
    // Recalcula quais movimentos sao possiveis.
    func detectPossibleSwaps() {
        var set = Set<Swap>()
        
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if let curso = cursos[column, row] {
                    
                    // Checa se é possivel mover o curso com outro da diretita?
                    // Note: nao precisa checar a ultima coluna
                    if column < NumColumns - 1 {
                        
                        // Checa se tem curso neste local
                        if let other = cursos[column + 1, row] {
                            // entao move
                            cursos[column, row] = other
                            cursos[column + 1, row] = curso
                            
                            // Checa se o curso faz part de uma cadeia
                            if hasChainAtColumn(column + 1, row: row) ||
                                hasChainAtColumn(column, row: row) {
                                    set.insert(Swap(cursoA: curso, cursoB: other))
                            }
                            
                            // move devolta
                            cursos[column, row] = curso
                            cursos[column + 1, row] = other
                        }
                    }
                    
                    // Checa se é possivel mover o curso com outro acima?
                    // Note: nao precisa checar a ultima linha
                    if row < NumRows - 1 {
                        
                        // Checa se tem curso neste local
                        if let other = cursos[column, row + 1] {
                            // entao move
                            cursos[column, row] = other
                            cursos[column, row + 1] = curso
                            
                            // Checa se o curso faz part de uma cadeia
                            if hasChainAtColumn(column, row: row + 1) ||
                                hasChainAtColumn(column, row: row) {
                                    set.insert(Swap(cursoA: curso, cursoB: other))
                            }
                            
                            // move devolta
                            cursos[column, row] = curso
                            cursos[column, row + 1] = other
                        }
                    }
                }
            }
        }
        
        possibleSwaps = set
    }
    
    // Um chain (cadeia) é 3 ou mais cursos consecutivos do mesmo tipo em uma linha ou coluna
    private func hasChainAtColumn(column: Int, row: Int) -> Bool {
        
        let cursoType = cursos[column, row]!.cursoType
        
        var horzLength = 1
        for var i = column - 1; i >= 0 && cursos[i, row]?.cursoType == cursoType; --i, ++horzLength {
            
        }
        for var i = column + 1; i < NumColumns && cursos[i, row]?.cursoType == cursoType; ++i, ++horzLength {
            
        }
        if horzLength >= 3 {
            return true
        }
        
        var vertLength = 1
        for var i = row - 1; i >= 0 && cursos[column, i]?.cursoType == cursoType; --i, ++vertLength {
            
        }
        for var i = row + 1; i < NumRows && cursos[column, i]?.cursoType == cursoType; ++i, ++vertLength {
            
        }
        return vertLength >= 3
    }
    
    
    
    // MARK: Detectando Pontuacoes
    
    // Detecta quando existe alguma cadeia de 3 ou mais cursos e os remove do jogo.
    // Retorna uma colecao contendo objetos Chain, que representa os Cursos que foram removidos.
    func removeMatches() -> Set<Chain> {
        let horizontalChains = detectHorizontalMatches()
        let verticalChains = detectVerticalMatches()
        
        removeCursos(horizontalChains)
        removeCursos(verticalChains)
        
        calculaPontuacao(horizontalChains)
        calculaPontuacao(verticalChains)
        
        //shuffeAutomatico()
        
        return horizontalChains.union(verticalChains)
    }
    
    private func detectHorizontalMatches() -> Set<Chain> {
        // Contem os objetos Curso que compoem uma pontuacao
        // Estes cursos devem ser removidos.
        var set = Set<Chain>()
        
        for row in 0..<NumRows {
            // Loop nao precisa verificar as 2 ultimas colunas
            for var column = 0; column < NumColumns - 2 ; {
                
                // Se existe curso nessa posicao entra...
                if let curso = cursos[column, row] {
                    let matchType = curso.cursoType
                    
                    // Verifica se as 2 proximas colunas sao do mesmo tipo...
                    if cursos[column + 1, row]?.cursoType == matchType &&
                        cursos[column + 2, row]?.cursoType == matchType {
                            
                            // ...entao adiciona todos os cursos da cadeia na colecao (set).
                            let chain = Chain(chainType: .Horizontal)
                            do {
                                chain.addCurso(cursos[column, row]!)
                                ++column
                            }
                            while column < NumColumns && cursos[column, row]?.cursoType == matchType
                            
                            set.insert(chain)
                            continue
                    }
                }
                
                // Curso nao fez ponto ou posicao vazia.
                ++column
            }
        }
        return set
    }
    
    private func detectVerticalMatches() -> Set<Chain> {
        var set = Set<Chain>()
        
        for column in 0..<NumColumns {
            for var row = 0; row < NumRows - 2; {
                if let curso = cursos[column, row] {
                    let matchType = curso.cursoType
                    
                    if cursos[column, row + 1]?.cursoType == matchType &&
                        cursos[column, row + 2]?.cursoType == matchType {
                            
                            let chain = Chain(chainType: .Vertical)
                            do {
                                chain.addCurso(cursos[column, row]!)
                                ++row
                            }
                            while row < NumRows && cursos[column, row]?.cursoType == matchType
                            
                            set.insert(chain)
                            continue
                    }
                }
                ++row
            }
        }
        return set
    }
    
    private func removeCursos(chains: Set<Chain>) {
        for chain in chains {
            for curso in chain.cursos {
                cursos[curso.column, curso.row] = nil
            }
        }
    }
    
    private func calculaPontuacao(chains: Set<Chain>) {
        // 3-chain == 60 pts, 4-chain == 120, 5-chain == 180...
        for chain in chains {
            chain.score = 60 * (chain.length - 2) * comboMultiplica
            ++comboMultiplica
        }
    }
    
    // Should be called at the start of every new turn.
    func resetComboMultiplica() {
        comboMultiplica = 1
    }

    
    // MARK: Detecting Holes

    func fillHoles() -> [[Curso]] {
        var columns = [[Curso]]()
        
        // Loop atraves da linhas debaixo pra cima.
        for column in 0..<NumColumns {
            var array = [Curso]()
            
            for row in 0..<NumRows {
                
                // Testa se tem um tile e nao tem curso na posicao.
                if tiles[column, row] != nil && cursos[column, row] == nil {
                    
                    for lookup in (row + 1)..<NumRows {
                        if let curso = cursos[column, lookup] {
                            // Troca o buraco com o curso.
                            cursos[column, lookup] = nil
                            cursos[column, row] = curso
                            curso.row = row
                            
                            // Para cada coluna, retorna um arrayde cursos que vao cair.
                            // Os cursos debaixo entram primeiro no array. Precisa dessa ordem
                            // para a animacao aplicar o delay correto.
                            array.append(curso)
                            
                            break
                        }
                    }
                }
            }
            
            if !array.isEmpty {
                columns.append(array)
            }
        }
        return columns
    }
    
    // Completa buracos do topo do array
    // Retorna um array que contem um sub-array para cada coluna que tem buracos,
    // com o novo objeto Curso. Cursos sao ordenados de cima para baixo.
    func topUpCursos() -> [[Curso]] {
        var columns = [[Curso]]()
        var cursoType: CursoType = .Unknown
        
        // Detecta onde deve adicionar novo curso. Se uma coluna tem X buracos,
        // entao precisa de X Cursos.
        for column in 0..<NumColumns {
            var array = [Curso]()
            
            // Varre de cima para baixo. Para quando encontra o primeiro curso.
            for var row = NumRows - 1; row >= 0 && cursos[column, row] == nil; --row {
                
                // Achou buraco?
                if tiles[column, row] != nil {
                    
                    // Cria um novo curso randomicamente. Nao pode ser igual ao proximo curso.
                    var newCursoType: CursoType
                    do {
                        newCursoType = CursoType.random()
                    } while newCursoType == cursoType
                    cursoType = newCursoType
                    
                    // Cria novo curso e adiciona no array desta coluna.
                    let curso = Curso(column: column, row: row, cursoType: cursoType)
                    cursos[column, row] = curso
                    array.append(curso)
                }
            }
            
            if !array.isEmpty {
                columns.append(array)
            }
        }
        
        
        return columns
    }
    
    
}