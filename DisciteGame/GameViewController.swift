//
//  GameViewController.swift
//  DisciteGame
//
//  Created by Paulo Henrique on 28/05/15.
//  Copyright (c) 2015 Scuny Corporation. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

class GameViewController: UIViewController {
    
    // Score
    var jogadas = 0
    var pontuacao = 0
    
    var num = 1
    
    lazy var backgroundMusic: AVAudioPlayer = {
        //let url = NSBundle.mainBundle().URLForResource("Mining by Moonlight", withExtension: "mp3")
        let url = NSBundle.mainBundle().URLForResource("Electrodoodle", withExtension: "mp3")
        //let url = NSBundle.mainBundle().URLForResource("Sneaky Snitch", withExtension: "mp3")
        let player = AVAudioPlayer(contentsOfURL: url, error: nil)
        player.volume = 0.2
        player.numberOfLoops = -1
        return player
    }()
    
    
    // Pre carregamento de resources
    //let levelCompleteSound = SKAction.playSoundFileNamed("LevelOK.wav", waitForCompletion: false)
    
    @IBOutlet weak var msnImagem: UIImageView!
    
    @IBOutlet weak var menLevel: UILabel!
    
    @IBOutlet weak var shuffleButton: UIButton!
    
    @IBOutlet weak var objetivoLabel: UILabel!
    @IBOutlet weak var jogadasLabel: UILabel!
    @IBOutlet weak var pontuacaoLabel: UILabel!
    
    @IBAction func shuffeButtonPressed(sender: AnyObject) {
        shuffle()
        decrementaJogadas()
    }
    
    var reconheceToque: UITapGestureRecognizer!
    
    
    // A scene desenha celulas (tiles) e sprites cursos
    var scene: GameScene!
    
    // level contem as celulas (tiles), os cursos, e a maioria da logica do gameplay.
    // Precisa ter ! pq nao é inicializado no init() mas no viewDidLoad().
    var level: Level!
    
    var movesLeft = 0
    var score = 0
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        backgroundMusic.play()
        
        // Inicia o game
        beginGame()
               
    }
    
    
    func showMensagemLevel() {
        msnImagem.hidden = false
        scene.userInteractionEnabled = false
        shuffleButton.hidden = true
        
        scene.animateMensagemLevel() {
            self.reconheceToque = UITapGestureRecognizer(target: self, action: "hiddeMensagemLevel")
            self.view.addGestureRecognizer(self.reconheceToque)
        }
        
    }

    func hiddeMensagemLevel() {
        view.removeGestureRecognizer(reconheceToque)
        reconheceToque = nil
        
        msnImagem.hidden = true
        scene.userInteractionEnabled = true
        
        beginGame()
    }
    
    
    func beginGame() {
        
        // Configura a View
        let skView = view as! SKView
        skView.multipleTouchEnabled = false
        
        msnImagem.hidden = true
        shuffleButton.hidden = true
        
        // Cria e Configura a Scene
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .AspectFill
       
        level = Level(filename: "Level_\(num)")
        
        scene.level = level
        scene.addTiles()
        scene.swipeHandler = handleSwipe
        
        
         // Apresenta Scene
        skView.presentScene(scene)
        
        movesLeft = level.maxJogadas
        score = 0
        
        updateLabels()

        level.resetComboMultiplica()
        
        
        scene.animateBeginGame() {
            self.shuffleButton.hidden = false
        }
        
        shuffle()
        
        
    }
    
    func shuffle() {
        
        // Completa o level com os cursos e cria sprites para eles.
        scene.removeAllCursosSprites()
        let newCursos = level.shuffle()
        scene.addSpritesForCursos(newCursos)
    }
    
    func handleSwipe(swap: Swap) {
        view.userInteractionEnabled = false
        
        if level.isPossibleSwap(swap) {
            
            level.performSwap(swap)
            scene.animateSwap(swap, completion: handleMatches)
        } else {
            scene.animateInvalidSwap(swap) {
                self.view.userInteractionEnabled = true
            }
        }
    }
    
    // Loop que remove grupo de pontuacao e completa os buracos com novos cursos.
    // Enguanto isso acontece o jogador nao pode interagir com o app.
    func handleMatches() {
        // Detecta se existe matches.
        let chains = level.removeMatches()
        
        // Se nao tem mais sequencias, libera game para o player.
        if chains.count == 0 {
            beginNextTurn()
            return
        }
        
        // Primeiro remove as sequencias...
        scene.animateMatchedCursos(chains)
        {
            // Atualiza nova pontuacao.
            for chain in chains {
                self.score += chain.score
            }
            self.updateLabels()
            
            // ...entao desce os cursos para os buracos que ficaram...
            let columns = self.level.fillHoles()
            self.scene.animateFallingCursos(columns) {
                
                // ...depois, cria os novos cursos no topo.
                let columns = self.level.topUpCursos()
                self.scene.animateNewCursos(columns) {
                    // Continua repetindo esse ciclo ate nao ter mais sequencias.
                    self.handleMatches()
                }
            }
        
        }
    }
    
    func beginNextTurn() {
        level.resetComboMultiplica()
        level.detectPossibleSwaps()
        view.userInteractionEnabled = true
        decrementaJogadas()
    }
    
    func decrementaJogadas(){
        
        --movesLeft
        updateLabels()
        
        if score >= level.objetivo {
            if(num == 5) {
                msnImagem.image = UIImage(named: "GameComplete")
                showMensagemLevel()
                num = 1
            }
            else {
                
                msnImagem.image = UIImage(named: "Level\(num)Complete")
                showMensagemLevel()
                ++num
            }
            
        } else if movesLeft == 0 {
            msnImagem.image = UIImage(named: "GameOver")
            showMensagemLevel()
            num = 1
        }
        
        
    }
    
    func updateLabels() {
        objetivoLabel.text = String(format: "%ld", level.objetivo)
        jogadasLabel.text = String(format: "%ld", movesLeft)
        pontuacaoLabel.text = String(format: "%ld", score)
        
    }
}
