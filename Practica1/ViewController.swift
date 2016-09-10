//
//  ViewController.swift
//  Practica1
//
//  Created by Michel on 07/09/16.
//  Copyright © 2016 Telstock. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imgFilm: Imagen!
    @IBOutlet weak var imgHeader: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblSynopsis: UILabel!
    
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var lblYear: UILabel!
    
    @IBOutlet weak var lblCriticScore: UILabel!
    @IBOutlet weak var lblAudienceScore: UILabel!
    
    // Session por defecto
    let defaultSession = NSURLSession(configuration:
        NSURLSessionConfiguration.defaultSessionConfiguration())
    
    // DataTask para hacer la petición a la api.
    var dataTask: NSURLSessionDataTask?
    
    // Imágenes de la película
    var urlFilmImage = "https://upload.wikimedia.org/wikipedia/en/6/6b/Beloved_Sisters.jpg"
    var urlFilmHeader = "https://image.tmdb.org/t/p/w780/AcJh8FcymkN3hEbhEYkaXUYzXC.jpg"
    
    //Objetos para parsear la información que devuelve la api
    var film = Film()
    var actors = [Actor]()
    var mov = Movie()!
    var rating = Rating()!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        
        // Se cargan las imágenes en los ImageView correspondientes.
        loadImageUrl(urlFilmImage, imageView: imgFilm)
        loadImageUrl(urlFilmHeader, imageView: imgHeader)
        
        // Se consume la api para obtener la info de la película
        cargarInfo()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // Función que carga una imagen en un ImageView desde una URL.
    func loadImageUrl(url: String, imageView: UIImageView) {
        let imageUrl = NSURL(string: url)
        let request: NSURLRequest = NSURLRequest(URL: imageUrl!)
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { (response: NSURLResponse?, data: NSData?, error: NSError?) in
            
            if error == nil {
                imageView.image = UIImage(data: data!)
            }
            
        }
    }

    // Función que obtiene la información de la película.
    func cargarInfo() {
        if dataTask != nil {
            dataTask?.cancel()
        }
        
        // Se notifica para que se nuestre el indicador de que hay una tarea de red.
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        // Se forma la url agregaron el nombre de la película, en este caso 'Beloved Sisters'
        let url = NSURL(string: "http://api.rottentomatoes.com/api/public/v1.0/movies.json?apikey=sabsf6qka779gqe3shgmf8da&q=Beloved+Sisters&page_limit=1")
        
        // Se ejecuta la petición a la api.
        dataTask = defaultSession.dataTaskWithURL(url!) { data, response, error in
            // Se oculta el indicador de la tarea
            dispatch_async(dispatch_get_main_queue()) {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
            // Manejo de la respuesta
            if let error = error {
                print(error.localizedDescription)
            } else if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print(data)
                    // Se carga la info en la tabla
                    self.updateSearchResults(data)
                }
            }
        }
        // Colocar parámetros
        //dataTask?.setValue("hi", forKey: "value")
        dataTask?.resume()
    }
    
    // Se parsea la info devuelta por la api.
    func updateSearchResults(data: NSData?) {
        do {
            if let data = data, response = try NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions(rawValue:0)) as? [String: AnyObject] {
                
                film = Film()
                film!.total = response["total"] as? Int
                
                var movies = [Movie]()
                mov = Movie()!
                
                rating = Rating()!
                
                actors = [Actor]()
                var act = Actor()
                
                // Se obtiene el arreglo de películas. En este caso 1 por que la búsqueda es limitada a una sola película.
                if let arrayMovies: AnyObject = response["movies"] {
                    for movie in arrayMovies as! [AnyObject] {
                        if let movie = movie as? [String: AnyObject] {
                            mov = Movie()!
                            mov.title = movie["title"] as? String
                            mov.synopsis = movie["synopsis"] as? String
                            mov.year = movie["year"] as? Int
                            mov.runtime = movie["runtime"] as? Int
                            rating.audience_score = (movie["ratings"] as? [String: AnyObject])!["audience_score"] as? Int
                            rating.critics_score = (movie["ratings"] as? [String: AnyObject])!["critics_score"] as? Int
                            mov.ratings = rating
                            if let arrayActor: AnyObject = movie["abridged_cast"] {
                                for actor in arrayActor as! [AnyObject] {
                                    act = Actor()
                                    act!.name = actor["name"] as? String
                                    act!.characters = (actor["characters"] as? [String])!
                                    actors.append(act!)
                                }
                                mov.actors = actors
                            }
                            movies.append(mov)
                            
                        } else {
                            print("Not a dictionary")
                        }
                    }
                    film!.movies = movies
                } else {
                    print("Results key not found in dictionary")
                }
            } else {
                print("JSON Error")
            }
        } catch let error as NSError {
            print("Error parsing results: \(error.localizedDescription)")
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
            self.tableView.setContentOffset(CGPointZero, animated: false)
            // Se establece la información de la película en sus respectivas etiquetas.
            self.lblTitle.text = self.mov.title
            self.lblYear.text = "\(self.mov.year!)"
            self.lblSynopsis.text = self.mov.synopsis
            self.lblTime.text = "\(self.mov.runtime!) minutes"
            self.lblCriticScore.text = "Critics Score: \(self.rating.critics_score!)"
            self.lblAudienceScore.text = "Audience Score: \(self.rating.audience_score!)"
        }
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Se establece el número de actores.
        return actors.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ActorCell", forIndexPath: indexPath) as! ActorCell
        // Se obtiene un actor/actriz de la lista.
        let actor = actors[indexPath.row]
        
        // Se establece el nombre del actor/actriz
        cell.nameActor.text = "Nombre: \(actor.name!)"
        // Se establece el nombre de los personajes interpretados por ese actor/actriz.
        var personajes = "Pensonaje(s): ";
        for i in 0..<actor.characters!.count {
            personajes += "\(actor.characters![i]) "
        }
        cell.nameCharacter.text = personajes
        
        return cell
    }
}
