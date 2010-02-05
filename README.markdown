Edytor szablonów Joggera
===============

Wymagania
---------
    ruby ;]

Instalacja
----------
    sudo gem install teamon-rubber


Konfiguracja
------------
    mkdir my_jogger
    cd my_jogger
    rubber configure


Pobranie plików z Joggera
-------------------------
    rubber download


Wysłanie zmodyfikowanych plików na Joggera
------------------------------------------
    rubber upload files/my_file.html


Wysłanie wszystkich plików na Joggera
-------------------------------------
    rubber upload files/*
    
    
Uruchomienie serwera
--------------------
    rubber server


Twój jogger jest dostępny pod adresem http://localhost:1337
Przykładowe treści można zmienić w pliku content.yml

Podgląd nowego wpisu
--------------------
Dodając plik do folderu posty o nazwie np. "nowy post.html" będzie on dostępny pod adresem http://localhost:1337/nowy%20post