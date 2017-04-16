//
//  bestMove.swift
//  kjchess
//
//  Copyright © 2017 Kristopher Johnson. All rights reserved.
//

import Foundation

/// Return the best move for the specified position.
///
/// - returns: A `Move` and the score, or `nil` if there are no legal moves.
public func bestMove(position: Position, searchDepth: Int = 1) -> (Move, Double)? {

    // TODO: Provide a better book-move generator than this.
    do {
        let b = position.board
        switch position.toMove {
        case .white:
            if b[e2] == WP && b[e3] == nil && b[e4] == nil {
                return (try position.find(coordinateMove: "e2e4"), 0.0)
            }
            else if b[g1] == WN && b[f3] == nil {
                return (try position.find(coordinateMove: "g1f3"), 0.0)
            }
        case .black:
            if b[e7] == BP && b[e6] == nil && b[e5] == nil {
                return (try position.find(coordinateMove: "e7e5"), 0.0)
            }
            else if b[b8] == BN && b[c6] == nil {
                return (try position.find(coordinateMove: "b8c6"), 0.0)
            }
        }
    }
    catch (let error) {
        assertionFailure("Unable to find move: \(error.localizedDescription)")
    }

    let moves = position.legalMoves()

    var bestMoves = [Move]()
    var bestScore: Double

    let queue = DispatchQueue(label: "bestMove")
    let group = DispatchGroup()

    switch position.toMove {
    case .white:
        bestScore = -Double.infinity
        for move in moves {
            group.enter()
            DispatchQueue.global().async {
                let moveScore = minimax(position: position.after(move),
                                        depth: searchDepth - 1)
                queue.sync {
                    if moveScore > bestScore {
                        bestScore = moveScore
                        bestMoves = [move]
                    }
                    else if moveScore == bestScore {
                        bestMoves.append(move)
                    }
                    group.leave()
                }
            }
        }
    case .black:
        bestScore = Double.infinity
        for move in moves {
            group.enter()
            DispatchQueue.global().async {
                let moveScore = minimax(position: position.after(move),
                                        depth: searchDepth - 1)
                queue.sync {
                    if moveScore < bestScore {
                        bestScore = moveScore
                        bestMoves = [move]
                    }
                    else if moveScore == bestScore {
                        bestMoves.append(move)
                    }
                    group.leave()
                }
            }
        }
    }

    group.wait()

    if let move = bestMoves.randomPick() {
        return (move, bestScore)
    }
    else {
        return nil
    }
}

private func minimax(position: Position, depth: Int) -> Double {

    if depth < 1 {
        let evaluation = Evaluation(position)
        return evaluation.score
    }

    let moves = position.legalMoves()

    var bestScore: Double

    switch position.toMove {
    case .white:
        bestScore = -Double.infinity
        for move in moves {
            let newPosition = position.after(move)
            let moveScore = minimax(position: newPosition,
                                    depth: depth - 1)
            bestScore = max(bestScore, moveScore)
        }
    case .black:
        bestScore = Double.infinity
        for move in moves {
            let newPosition = position.after(move)
            let moveScore = minimax(position: newPosition,
                                    depth: depth - 1)
            bestScore = min(bestScore, moveScore)
        }
    }

    return bestScore
}
