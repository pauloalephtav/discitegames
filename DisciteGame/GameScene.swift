//
//  GameScene.swift
//  DisciteGame
//
//  Created by Paulo Henrique on 28/05/15.
//  Copyright (c) 2015 Scuny Corporation. All rights reserved.
//

import SpriteKit


class GameScene: SKScene {
    
    var level: Level!
    
    // The scene handles touches. If it recognizes that the user makes a swipe,
    // it will call this swipe handler. This is how it communicates back to the
    // ViewController that a swap needs to take place. You could also use a
    // delegate for this.
    var swipeHandler: ((Swap) -> ())?

    
    // The column and row numbers of the cookie that the player first touched
    // when he started his swipe movement. These are marked ? because they may
    // become nil (meaning no swipe is in progress).
    var swipeFromColumn: Int?
    var swipeFromRow: Int?
    
    // Tamanho do quadrado do Grid 2D
    let tileLargura: CGFloat = 32.0
    let tileAltura: CGFloat = 36.0
    
    // Camadas (gameLayer MAE)
    let gameLayer = SKNode()
    let cursosLayer = SKNode()
    let tilesLayer = SKNode()
    let cropLayer = SKCropNode()
    let maskLayer = SKNode()
    
    
    // Sprite desenhada em cima do curso que o usuario esta tentando deslizar
    var selectionSprite = SKSpriteNode()
    
    // Pre carregamento de resources
    let swapSound = SKAction.playSoundFileNamed("Bell.wav", waitForCompletion: false)
    let invalidSwapSound = SKAction.playSoundFileNamed("Error.wav", waitForCompletion: false)
    let matchSound = SKAction.playSoundFileNamed("Ka-Ching.wav", waitForCompletion: false)
    let fallingCursoSound = SKAction.playSoundFileNamed("Scrape.wav", waitForCompletion: false)
    let addCursoSound = SKAction.playSoundFileNamed("Drip.wav", waitForCompletion: false)
    
    
    
    // MARK: Game Setup
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder) não foi usado neste app")
    }
    
    
    // Inicializa camadas
    override init(size: CGSize) {
        
        swipeFromColumn = nil
        swipeFromRow = nil
        
        
        // Inicializa Background Layer
        super.init(size: size)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let background = SKSpriteNode(imageNamed: "Background")
        addChild(background)
        

        addChild(gameLayer)
        let layerPosition = CGPoint(x: -tileLargura * CGFloat(NumColumns) / 2, y: -tileAltura * CGFloat(NumRows) / 2)
        
        // Inicialize tilesLayer
        tilesLayer.position = layerPosition
        gameLayer.addChild(tilesLayer)
        
        // Cria adicional layer
        // a layer cropLayer desenha children apenas a mascara contem pixel
        gameLayer.addChild(cropLayer)
        maskLayer.position = layerPosition
        cropLayer.maskNode = maskLayer
        
        gameLayer.hidden = true
        
        //cropLayer.addChild(maskLayer)
        
        // Inicializa gameLayer
        cursosLayer.position = layerPosition
        cropLayer.addChild(cursosLayer)
        
        // Layer do labey de pontuacao
        SKLabelNode(fontNamed: "GillSans-BoldItalic")
        
        
    }
    
    func removeAllCursosSprites() {
        cursosLayer.removeAllChildren()
    }

    
    // Funcao para adicionar tiles atras dos cursos
    func addTiles() {
        
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if let tile = level.tileAtColumn(column, row: row) {
                    let tileNode = SKSpriteNode(imageNamed: "MaskTile")
                    tileNode.position = pointForColumn(column, row: row)
                    maskLayer.addChild(tileNode)
                }
            }
        }
        
        // A textura tile e desenhada "entre" o level tiles.
        // Isto porque existe uma coluna e linha extra.
        for row in 0...NumRows {
            for column in 0...NumColumns {
                
                let topLeft     = (column > 0) && (row < NumRows)
                    && level.tileAtColumn(column - 1, row: row) != nil
                let bottomLeft  = (column > 0) && (row > 0)
                    && level.tileAtColumn(column - 1, row: row - 1) != nil
                let topRight    = (column < NumColumns) && (row < NumRows)
                    && level.tileAtColumn(column, row: row) != nil
                let bottomRight = (column < NumColumns) && (row > 0)
                    && level.tileAtColumn(column, row: row - 1) != nil
                
                // Os tiles estao nomeados de 0 a 15, de acordo com os 4 valores combinados.
                let value = Int(topLeft) | Int(topRight) << 1 | Int(bottomLeft) << 2 | Int(bottomRight) << 3
                
                // Valor 0 (sem tiles), 6 e 9 (2 tiles opostos) nao sao desenhados.
                if value != 0 && value != 6 && value != 9 {
                    let name = String(format: "Tile_%ld", value)
                    let tileNode = SKSpriteNode(imageNamed: name)
                    var point = pointForColumn(column, row: row)
                    point.x -= tileAltura/2
                    point.y -= tileLargura/2
                    tileNode.position = point
                    tilesLayer.addChild(tileNode)
                }
            }
        }
    }
    
    // Adiciona sprites para os cursos
    func addSpritesForCursos(cursos: Set<Curso>) {
        
        for curso in cursos {
            let sprite = SKSpriteNode(imageNamed: curso.cursoType.spriteName)
            sprite.position = pointForColumn(curso.column, row: curso.row)
            cursosLayer.addChild(sprite)
            curso.sprite = sprite
            
            sprite.alpha = 0
            sprite.xScale = 0.5
            sprite.yScale = 0.5
            
            sprite.runAction(
                SKAction.sequence([
                    SKAction.waitForDuration(0.25, withRange: 0.5),
                    SKAction.group([
                        SKAction.fadeInWithDuration(0.25),
                        SKAction.scaleTo(1.0, duration: 0.25)
                        ])
                    ]))
        }
        
    }
    
    // MARK: Conversion Routines
    
    // Converte o numero de coluna e linha em CGPoint
    func pointForColumn(column: Int, row: Int) -> CGPoint {
        return CGPoint(x: CGFloat(column) * tileLargura + tileLargura / 2, y: CGFloat(row) * tileAltura + tileAltura / 2)
    }
    
    // Converte um CGPoint para uma coluna e linha
    func convertPoint(point: CGPoint) -> (succes: Bool, column: Int, row: Int) {
        if point.x >= 0 && point.x < CGFloat(NumColumns) * tileLargura && point.y >= 0 && point.y < CGFloat(NumRows) * tileAltura {
            return (true, Int(point.x / tileLargura), Int(point.y / tileAltura))
        } else {
            return (false, 0, 0)
        }
    }
    
    
    // MARK: Detecting Swipes
    
    // Detecta as trocas
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        // Converte a posicao do toque para um ponto relativo no cursoLayer
        let touch = touches.first as! UITouch
        let location = touch.locationInNode(cursosLayer)
        
        // Se o toque é dentro de um quadrado, entao pode iniciar um movimento swipe
        let (success, column, row) = convertPoint(location)
        if success {
            
            // O toque deve ser em um curso, nano em um tile vazio.
            if let curso = level.cursoAtColumn(column, row: row) {
                
                // Relembra em qual coluna e linha a troca comecou, entao podemos comparar
                // o ponto anterior para achar a direcao da troca. Este tbm é o primeiro
                // curso que sera trocado.
                swipeFromColumn = column
                swipeFromRow = row
                
                showSelecttionIndicatorForCurso(curso)
            }
        }
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        // Se swipeFromColumn é nil entao o movimento comecou fora de uma area valida
        // ou o jogo ja tinha movido o curso e nos precisamos ignorar o resto dos movimentos.
        if swipeFromColumn == nil { return }
        
        // Testar em qual direcao o jogador movel. Movimentos diagonais nao permitidos.
        let touch = touches.first as! UITouch
        let location = touch.locationInNode(cursosLayer)
        
        let (success, column, row) = convertPoint(location)
        if success {
            //
            var horzDelta = 0, vertDelta = 0
            if column < swipeFromColumn! {        // Swipe Esquerda
                horzDelta = -1
            } else if column > swipeFromColumn! {  // Swipe Direita
                horzDelta = 1
            } else if row < swipeFromRow! {         // Swipe pra Baixo
                vertDelta = -1
            } else if row > swipeFromRow! {         // Swipe pra Cima
                vertDelta = 1
            }
            // Apenas tenta deslizar quando o usuario deslizar para um novo quadrado.
            if horzDelta != 0 || vertDelta != 0 {
                trySwapHorizontal(horzDelta, vertical: vertDelta)
                hideSelectionIndicator()
                
                swipeFromColumn = nil
            }
        }
    }
    
    // Essa funcao ocorre apos o jogador efetuar um swipe. Isso dispara uma cadeia de eventos:
    // 1) troca os cursos, 2) remove as linhas de cursos combinados, 3) desce novos cursos na tela
    // 4) checa se foram criadas novas combinacoes.
    func trySwapHorizontal(horzDelta: Int, vertical vertDelta: Int) {
        
        let toColumn = swipeFromColumn! + horzDelta
        let toRow = swipeFromRow! + vertDelta
        
        // Testa se o movimento foi pra fora do array e ignora.
        if toColumn < 0 || toColumn >= NumColumns { return }
        if toRow < 0 || toRow >= NumRows { return }
        
        // Testa se o movimento é para area sem tile.
        if let toCurso = level.cursoAtColumn(toColumn, row: toRow) {
            if let fromCurso = level.cursoAtColumn(swipeFromColumn!, row: swipeFromRow!) {
                if let handler = swipeHandler {
                
                    // Comunica a troca pro ViewController.
                    let swap = Swap(cursoA: fromCurso, cursoB: toCurso)
                    handler(swap)
                    //println("*** swapping \(fromCurso) with \(toCurso)")
                }
            }
        }
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        // Remove o indicador de selecao.
        if selectionSprite.parent != nil && swipeFromColumn != nil {
            hideSelectionIndicator()
        }
        
        // Se o gesto acabou resetar o numero de coluna e linha
        swipeFromColumn = nil
        swipeFromRow = nil
    }
    
    override func touchesCancelled(touches: Set<NSObject>, withEvent event: UIEvent) {
        touchesEnded(touches, withEvent: event)
    }
    
    // MARK: Animations
    func animateSwap(swap: Swap, completion: () -> ()) {
        let spriteA = swap.cursoA.sprite!
        let spriteB = swap.cursoB.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let Duration: NSTimeInterval = 0.3
        
        let moveA = SKAction.moveTo(spriteB.position, duration: Duration)
        moveA.timingMode = .EaseOut
        spriteA.runAction(moveA, completion: completion)
        
        let moveB = SKAction.moveTo(spriteA.position, duration: Duration)
        moveB.timingMode = .EaseOut
        spriteB.runAction(moveB)
        
        runAction(swapSound)
        
    }
    
    func animateInvalidSwap(swap: Swap, completion: () -> ()) {
        let spriteA = swap.cursoA.sprite!
        let spriteB = swap.cursoB.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let Duration: NSTimeInterval = 0.2
        
        let moveA = SKAction.moveTo(spriteB.position, duration: Duration)
        moveA.timingMode = .EaseOut
        
        let moveB = SKAction.moveTo(spriteA.position, duration: Duration)
        moveB.timingMode = .EaseOut
        
        spriteA.runAction(SKAction.sequence([moveA, moveB]), completion: completion)
        spriteB.runAction(SKAction.sequence([moveB, moveA]))
        
        runAction(invalidSwapSound)
    }
    
    func animateMatchedCursos(chains: Set<Chain>, completion: () -> ()) {
        for chain in chains {
            // Chama animacao da cadeia de cursos
            animatePontuacao(chain)
            for curso in chain.cursos {
                
                // Verifica se o o objeto Curso faz parte de mais de uma chain.
                // Nesse caso, anima a remocao apenas uma vez.
                if let sprite = curso.sprite {
                    if sprite.actionForKey("removing") == nil {
                        let scaleAction = SKAction.scaleTo(0.1, duration: 0.3)
                        scaleAction.timingMode = .EaseOut
                        sprite.runAction(SKAction.sequence([scaleAction, SKAction.removeFromParent()]),
                            withKey:"removing")
                    }
                }
            }
        }
        runAction(matchSound)
        
        // Continue com o jogo apos animacao acabar.
        runAction(SKAction.waitForDuration(0.3), completion: completion)
    }
    
    func animateFallingCursos(columns: [[Curso]], completion: () -> ()) {
        var longestDuration: NSTimeInterval = 0
        for array in columns {
            for (idx, curso) in enumerate(array) {
                let newPosition = pointForColumn(curso.column, row: curso.row)
                
                // Quanto mais longe do buraco, maior é o daley da animacao.
                let delay = 0.05 + 0.15*NSTimeInterval(idx)
                
                let sprite = curso.sprite!
                
                // Calcula a duracao baseado na distancia do curso para cair (0.1 segundos por tile).
                let duration = NSTimeInterval(((sprite.position.y - newPosition.y) / tileAltura) * 0.1)
                longestDuration = max(longestDuration, duration + delay)
                
                let moveAction = SKAction.moveTo(newPosition, duration: duration)
                moveAction.timingMode = .EaseOut
                sprite.runAction(
                    SKAction.sequence([
                        SKAction.waitForDuration(delay),
                        SKAction.group([moveAction, fallingCursoSound])]))
            }
        }
        
        // Espera ate a animacao acabar.
        runAction(SKAction.waitForDuration(longestDuration), completion: completion)
    }
    
    func animateNewCursos(columns: [[Curso]], completion: () -> ()) {
        // Para nao continuar com o jogo ate a animacao acabar, calcula quanto tempo
        // a animacao vai demorar.
        var longestDuration: NSTimeInterval = 0
        
        for array in columns {
            
        
            let startRow = array[0].row + 1
            
            for (idx, curso) in enumerate(array) {
                
                // Cria um novo sprite do curso.
                let sprite = SKSpriteNode(imageNamed: curso.cursoType.spriteName)
                sprite.position = pointForColumn(curso.column, row: startRow)
                cursosLayer.addChild(sprite)
                curso.sprite = sprite
                
                // Dalay para cada curso do mais alto para o mais longe.
                let delay = 0.1 + 0.2 * NSTimeInterval(array.count - idx - 1)
                
                // Calcula duracao da animacao baseado na distancia do curso que vai cair.
                let duration = NSTimeInterval(startRow - curso.row) * 0.1
                longestDuration = max(longestDuration, duration + delay)
                
                // Anima sprite caindo.
                let newPosition = pointForColumn(curso.column, row: curso.row)
                let moveAction = SKAction.moveTo(newPosition, duration: duration)
                moveAction.timingMode = .EaseOut
                sprite.alpha = 0
                sprite.runAction(
                    SKAction.sequence([
                        SKAction.waitForDuration(delay),
                        SKAction.group([
                            SKAction.fadeInWithDuration(0.05),
                            moveAction,
                            addCursoSound])
                        ]))
            }
        }
        // Espera ate a animacao acabar.
        runAction(SKAction.waitForDuration(longestDuration), completion: completion)
    }
    
    func animatePontuacao(chain: Chain) {
        // Acha a posicao da cadeia de cursos.
        let firstSprite = chain.firstCurso().sprite!
        let lastSprite = chain.lastCurso().sprite!
        let centerPosition = CGPoint(
            x: (firstSprite.position.x + lastSprite.position.x)/2,
            y: (firstSprite.position.y + lastSprite.position.y)/2 - 8)
        
        // AAdiciona o label flutuando em cima dos cursos.
        let scoreLabel = SKLabelNode(fontNamed: "GillSans-BoldItalic")
        scoreLabel.fontSize = 16
        scoreLabel.text = String(format: "%ld", chain.score)
        scoreLabel.position = centerPosition
        scoreLabel.zPosition = 300
        cursosLayer.addChild(scoreLabel)
        
        let moveAction = SKAction.moveBy(CGVector(dx: 0, dy: 3), duration: 0.7)
        moveAction.timingMode = .EaseOut
        scoreLabel.runAction(SKAction.sequence([moveAction, SKAction.removeFromParent()]))
    }
    
    func animateMensagemLevel(completion: () -> ()) {
        let action = SKAction.moveBy(CGVector(dx: 0, dy: -size.height), duration: 0.3)
        action.timingMode = .EaseIn
        gameLayer.runAction(action, completion: completion)
    }
    
    func animateBeginGame(completion: () -> ()) {
        gameLayer.hidden = false
        gameLayer.position = CGPoint(x: 0, y: size.height)
        let action = SKAction.moveBy(CGVector(dx: 0, dy: -size.height), duration: 0.3)
        action.timingMode = .EaseOut
        gameLayer.runAction(action, completion: completion)
    }



    
    // MARK: Selection Indicator
    
    func showSelecttionIndicatorForCurso(curso: Curso) {
        // Se o indicador de selecao ainda estiver visivel, remova-o
        if selectionSprite.parent != nil {
            selectionSprite.removeFromParent()
        }
        
        // Adiciona o indicador de selecao como filho para o curso que o jogador
        // tocou para disfarcar.
        if let sprite = curso.sprite {
            let texture = SKTexture(imageNamed: curso.cursoType.highlightedSpriteName)
            selectionSprite.size = texture.size()
            selectionSprite.runAction(SKAction.setTexture(texture))
            
            sprite.addChild(selectionSprite)
            selectionSprite.alpha = 1.0
        }
    }
    
    func hideSelectionIndicator() {
        selectionSprite.runAction(SKAction.sequence([
            SKAction.fadeOutWithDuration(0.3),
            SKAction.removeFromParent()]))
    }



    
    
}
