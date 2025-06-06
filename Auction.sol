// SPDX-License-Identifier: MIT
pragma solidity  ^0.8;

contract Auction {

    // VARIABLES DE ESTADO: 

    // Sobre Bids COMPLETADAS
    uint256 entryBid = 1; // Bid minimo de entrada a la subasta
    address public highestBidder; // Address de la wallet del buyer con mayor bid
    uint256 public highestBid; // Monto del mayor bid

    address seller = 0x742d35Cc6634C0532925a3b844Bc454e4438f44e; // Un vendedor

    // Debe ser muchos vendedores
    struct Buyer {
        uint256 totalBid;
        bool claimed;
        // Agregar mas campos
    }
    mapping(address => Buyer) public buyers;

    address[] public buyerAddresses; // Esto es un array o un bytes?

    // Duración de la Subasta => COMPLETADO
    uint256 startAuctionTimestamp; // Tiempo para iniciar la subasta
    uint256 public auctionEndTime; // 1 hora o 3600 segundos o ajustar
    uint256 constant EXTENSION_TIME = 600; // 10 minutos en segundos

    // Caja de seguridad para los depositos de los bid's.
    uint256 safeBox = 0; 


    //FUNCIONES:
    // Constructor. Inicializa la subasta con los parámetros necesario para su funcionamiento.
    constructor (uint256 _duration, uint256 _entryBid) {
        // TODO: Definir tus valores iniciales de la subasta.
        require(_entryBid >= entryBid, 'El monto es muy bajo'); // Verifica el minimo del bid
        entryBid = _entryBid; // sobreescribe el valor de entryBid

        startAuctionTimestamp = block.timestamp; // Inicia el tiempo de la Subasta
        auctionEndTime = block.timestamp + _duration; // Paso la duracion de la subasta, pero como hago en caso de bid-extras?
    }

    // === FUNCIONES ADICIONALES ===
    function hasAuctionClosed () public view returns (bool) {
        // Como agregar el tiempo de duracion de la Subasta?
        return block.timestamp >= startAuctionTimestamp + auctionEndTime;
    }

    // Modificadores
    modifier whileAuctionOpen () {
        // Asegurar que algunas funciones solo se ejecuten durante el tiempo de subasta
        require(block.timestamp <  startAuctionTimestamp + auctionEndTime, "Subasta cerrada");
        _;
    }

    modifier whenAuctionClosed () {
        // Asegurar que algunas funciones solo cuando la subasta finalizo
        require(block.timestamp >=  startAuctionTimestamp + auctionEndTime, "Subasta activa");
        _;
    }

    // === FUNCION PARA OFERTAR ===
    // Función para ofertar: Permite a los participantes ofertar por el artículo.
    // Para que una oferta sea válida debe ser mayor que la mayor oferta actual al menos en 5% y
    // debe realizarse mientras la subasta esté activa.
    function setBid( ) public payable whileAuctionOpen {
        // TODO: Agregar la logica para la oferta

        uint256 newBid = msg.value; 
        require(newBid >= entryBid, "Debes ofertar al menos el minimo de entrada"); // Idealmente seria el primer Bid ?
        require(newBid >= highestBid + (highestBid * 5) /100, "Debes superar la mejor oferta en al menos 5%" );

        Buyer storage buyer = buyers[msg.sender];

        // Reembolsar la oferta anterior del mejor postor (más adelante podés permitir retirarlo manualmente)
        if (buyer.totalBid == 0) {
            buyerAddresses.push(msg.sender);
        }

        buyer.totalBid += newBid;
        highestBidder = msg.sender;
        highestBid = buyer.totalBid;

        
         // Si quedan 10 minutos o menos para que termine la subasta
        if (auctionEndTime - block.timestamp <= EXTENSION_TIME) {
            auctionEndTime = block.timestamp + EXTENSION_TIME;
        }
         
        // Emitir evento, es como invocarlo
        emit NewBidEvent(msg.sender, buyer.totalBid);
    }

    // === FUNCION MOSTRAR GANADOR ===
    // Mostrar ganador: Muestra el ofertante ganador y el valor de la oferta ganadora.
    function showWinner () public whenAuctionClosed {
        // Logica para mostrar el buyer, primero resolver los mapping bids y buyers
    }

    // === FUNCION MOSTRAR OFERTAS ===
    // Mostrar ofertas: Muestra la lista de ofertantes y los montos ofrecidos.
    function showAllBids () public view whileAuctionOpen returns(address[] memory, uint256[] memory) {
        // Logica para mostrar las ofertas y sus ofertantes
        uint256[] memory amounts = new uint256[](buyerAddresses.length);
        for (uint i = 0; i < buyerAddresses.length; i++) {
            amounts[i] = buyers[buyerAddresses[i]].totalBid;
        }
        return (buyerAddresses, amounts);
    }

    // === FUNCION DEVOLVER DEPOSITOS ===
    // Devolver depósitos: Al finalizar la subasta se devuelve el depósito a los ofertantes que 
    //no ganaron, descontando una comisión del 2% para el gas.
    function claimDeposit () public whenAuctionClosed {}

    // MANEJO DE DEPOSITOS:
    // Las ofertas se depositan en el contrato y se almacenan con las direcciones de los ofertantes.
    function handlerDeposit () public {}

    // EVENTOS:
    // Nueva Oferta: Se emite cuando se realiza una nueva oferta.
    event NewBidEvent (address indexed bidder, uint256 amount);

    // Subasta Finalizada: Se emite cuando finaliza la subasta.
    event AuctionFinished ();

    // FUNCIONALIDADES AVANZADAS:
    // Reembolso parcial:
    // Los participantes pueden retirar de su depósito el importe por encima de su última oferta 
    // durante el desarrollo de la subasta.

    function partialClaim () public whileAuctionOpen {}

    // Consideraciones adicionales:
    /* 
    - Se debe utilizar modificadores cuando sea conveniente.
    - Para superar a la mejor oferta la nueva oferta debe ser superior al menos en 5%.
    - El plazo de la subasta se extiende en 10 minutos con cada nueva oferta válida. Esta regla aplica siempre a partir de 10 minutos antes del plazo original de la subasta. De esta manera los competidores tienen suficiente tiempo para presentar una nueva oferta si así lo desean.
    - El contrato debe ser seguro y robusto, manejando adecuadamente los errores y las posibles situaciones excepcionales.
    - Se deben utilizar eventos para comunicar los cambios de estado de la subasta a los participantes.
    - La documentación del contrato debe ser clara y completa, explicando las funciones, variables y eventos.
    */
}