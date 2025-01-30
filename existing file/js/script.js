let menu = document.querySelector('#menu');
let navbar = document.querySelector('.navbar');

menu.onclick = () => {
    menu.classList.toggle('fa-times');
    navbar.classList.toggle('active');
}

window.onscroll = () => {
    menu.classList.remove('fa-times');
    navbar.classList.remove('active');
}


const chapterSlideCounts = [9, 10, 11];

let currentChapter = 0;
let currentSlide = 0;

// Function to open a chapter
function openChapter(chapterIndex) {
    currentChapter = chapterIndex;
    currentSlide = 0;
    displaySlide();
}

// Function to display the current slide
function displaySlide() {
    const chapterImage = document.getElementById('chapterImage');
    const slideCount = chapterSlideCounts[currentChapter];

    if (currentSlide < slideCount) {
        // Construct the image path dynamically based on chapter and slide number
        chapterImage.src = `../Presentation${currentChapter + 1}/Slide${currentSlide + 1}.png`;
    }
}

// Function to go to the next slide
function nextSlide() {
    if (currentSlide < chapterSlideCounts[currentChapter] - 1) {
        currentSlide++;
        displaySlide();
    } 
}

// Function to go to the previous slide
function prevSlide() {
    if (currentSlide > 0) {
        currentSlide--;
        displaySlide();
    }
}

// Function to toggle full screen
function toggleFullScreen() {
    const chapterDisplay = document.getElementById('chapterDisplay');
    if (!document.fullscreenElement) {
        chapterDisplay.requestFullscreen().catch(err => console.log(err));
    } else {
        document.exitFullscreen();
    }
}
// Function to close the chapter view
function closeChapter() {
    const chapterImage = document.getElementById('chapterImage');
    chapterImage.src = '';
    document.exitFullscreen();
}

function validateEmail() {
    const emailInput = document.getElementById('email');
    const emailValue = emailInput.value;
    const emailPattern = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

    if (!emailPattern.test(emailValue)) {
        alert('Please enter a valid email address.');
        emailInput.focus();
        return false;
    }
    return true;
}
