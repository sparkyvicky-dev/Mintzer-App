(function initMobileNav() {
    const menuBtn = document.querySelector('.mobile-nav-btn');
    if (!menuBtn) return;

    menuBtn.addEventListener('click', () => {
        menuBtn.classList.toggle('active');
    });
})();

(function initProcessSection() {
    const processSlider = document.querySelector('.process-cards');
    const cards = Array.from(document.querySelectorAll('.process-card'));
    const dots = Array.from(document.querySelectorAll('.process-slider-dot'));

    if (!processSlider || !cards.length) return;

    function updateDotState(activeIndex) {
        dots.forEach((dot, index) => {
            const isActive = index === activeIndex;
            dot.classList.toggle('active', isActive);
            dot.setAttribute('aria-current', isActive ? 'true' : 'false');
        });
    }

    function setActiveCard(activeIndex) {
        cards.forEach((card, index) => {
            card.classList.toggle('active', index === activeIndex);
        });
        if (dots.length) updateDotState(activeIndex);
    }

    function setEqualHeight() {
        cards.forEach((card) => {
            card.style.minHeight = 'auto';
        });

        if (window.innerWidth <= 700) return;

        const activeCard = document.querySelector('.process-card.active');

        if (!activeCard) return;

        const height = activeCard.offsetHeight;

        cards.forEach((card) => {
            card.style.minHeight = height + 'px';
        });
    }

    function onHover(event) {
        setActiveCard(cards.indexOf(event.currentTarget));
        setEqualHeight();
    }

    function bindHover() {
        cards.forEach((card) => {
            card.removeEventListener('mouseenter', onHover);
        });

        if (window.innerWidth > 1280) {
            cards.forEach((card) => {
                card.addEventListener('mouseenter', onHover);
            });
        }
    }

    function updateSliderFromScroll() {
        if (window.innerWidth > 700) return;

        const nearestIndex = cards.reduce((closestIndex, card, index) => {
            const currentDistance = Math.abs(processSlider.scrollLeft - card.offsetLeft);
            const closestDistance = Math.abs(processSlider.scrollLeft - cards[closestIndex].offsetLeft);

            return currentDistance < closestDistance ? index : closestIndex;
        }, 0);

        setActiveCard(nearestIndex);
    }

    function handleResponsive() {
        bindHover();

        if (window.innerWidth <= 700) {
            updateSliderFromScroll();
        } else if (window.innerWidth <= 1280) {
            cards.forEach((card) => {
                card.classList.add('active');
            });
            if (dots.length) updateDotState(1);
        } else {
            setActiveCard(1);
        }

        setEqualHeight();
    }

    dots.forEach((dot, index) => {
        dot.addEventListener('click', () => {
            if (window.innerWidth > 700) return;

            processSlider.scrollTo({
                left: cards[index].offsetLeft,
                behavior: 'smooth'
            });

            setActiveCard(index);
        });
    });

    processSlider.addEventListener('scroll', updateSliderFromScroll, { passive: true });
    window.addEventListener('load', handleResponsive);
    window.addEventListener('resize', handleResponsive);
    handleResponsive();
})();

window.addEventListener('load', () => {
    const carousel = document.querySelector('.tab-pane-carousel');
    const buttons = document.querySelectorAll('.carousel-switches button');
    const indicator = document.querySelector('.tab-pane-indicator');
    const indicatorStroke = document.querySelector('.tab-pane-indicator-stroke');
    const contents = document.querySelectorAll('.tab-pane-container');

    if (!carousel || !buttons.length || !contents.length || !indicator || !indicatorStroke) return;

    const tabAutoMs = 8000;
    const indicatorStrokeWidth = 2;
    let currentIndex = 0;
    let tabAdvanceTimeout = null;
    let tabArcRaf = null;
    let tabProgress = 0;
    let indicatorPathLength = 0;
    let isCarouselInView = false;
    const prefersReducedMotion = () => window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    const svgNs = 'http://www.w3.org/2000/svg';
    const indicatorRing =
        indicatorStroke.querySelector('.tab-pane-indicator-ring') || document.createElementNS(svgNs, 'svg');
    const indicatorRingPath = indicatorRing.querySelector('path') || document.createElementNS(svgNs, 'path');

    indicatorRing.classList.add('tab-pane-indicator-ring');
    indicatorRing.setAttribute('aria-hidden', 'true');
    indicatorRingPath.setAttribute('fill', 'none');

    if (!indicatorRing.contains(indicatorRingPath)) {
        indicatorRing.appendChild(indicatorRingPath);
    }
    if (!indicatorStroke.contains(indicatorRing)) {
        indicatorStroke.appendChild(indicatorRing);
    }

    function canAutoPlay() {
        return isCarouselInView && !document.hidden;
    }

    function setIndicatorProgress(progress) {
        tabProgress = Math.min(Math.max(progress, 0), 1);

        if (!indicatorPathLength) {
            return;
        }

        indicatorRingPath.style.strokeDasharray = String(indicatorPathLength);
        indicatorRingPath.style.strokeDashoffset = String(indicatorPathLength * (1 - tabProgress));
    }

    function updateIndicatorRing(width, height) {
        const inset = indicatorStrokeWidth / 2;
        const svgWidth = width + indicatorStrokeWidth;
        const svgHeight = height + indicatorStrokeWidth;
        const innerWidth = Math.max(svgWidth - indicatorStrokeWidth, 0);
        const innerHeight = Math.max(svgHeight - indicatorStrokeWidth, 0);
        const radius = innerHeight / 2;
        const top = inset;
        const left = inset;
        const right = left + innerWidth;
        const bottom = top + innerHeight;
        const centerY = top + radius;
        const centerTopX = left + innerWidth / 2;
        const rightStraightEndX = Math.max(right - radius, centerTopX);
        const leftStraightStartX = left + radius;

        indicatorRing.setAttribute('viewBox', `0 0 ${svgWidth} ${svgHeight}`);
        indicatorRing.setAttribute('width', String(svgWidth));
        indicatorRing.setAttribute('height', String(svgHeight));
        // Path starts at left center (not top center) so the stroke "grows" from the middle of the left edge.
        indicatorRingPath.setAttribute(
            'd',
            [
                `M ${left} ${centerY}`,
                `A ${radius} ${radius} 0 0 1 ${leftStraightStartX} ${top}`,
                `H ${rightStraightEndX}`,
                `A ${radius} ${radius} 0 0 1 ${right} ${centerY}`,
                `A ${radius} ${radius} 0 0 1 ${rightStraightEndX} ${bottom}`,
                `H ${leftStraightStartX}`,
                `A ${radius} ${radius} 0 0 1 ${left} ${centerY}`
            ].join(' ')
        );

        indicatorPathLength = indicatorRingPath.getTotalLength();
        setIndicatorProgress(tabProgress);
    }

    function updateIndicator() {
        const activeBtn = buttons[currentIndex];
        if (!activeBtn) {
            return;
        }

        const left = activeBtn.offsetLeft + 'px';
        const top = activeBtn.offsetTop + 'px';
        const w = activeBtn.offsetWidth + 'px';
        const h = activeBtn.offsetHeight + 'px';
        indicator.style.left = left;
        indicator.style.top = top;
        indicator.style.width = w;
        indicator.style.height = h;
        indicatorStroke.style.left = left;
        indicatorStroke.style.top = top;
        indicatorStroke.style.width = w;
        indicatorStroke.style.height = h;
        updateIndicatorRing(activeBtn.offsetWidth, activeBtn.offsetHeight);
    }

    function syncCarouselLayout() {
        indicator.style.display = 'block';
        indicatorStroke.style.display = 'block';
        updateIndicator();
    }

    function stopTabTimer() {
        if (tabArcRaf != null) {
            cancelAnimationFrame(tabArcRaf);
            tabArcRaf = null;
        }
        if (tabAdvanceTimeout != null) {
            clearTimeout(tabAdvanceTimeout);
            tabAdvanceTimeout = null;
        }
        setIndicatorProgress(0);
    }

    function restartTabTimer() {
        stopTabTimer();
        indicatorStroke.classList.remove('is-timing');
        if (!canAutoPlay()) {
            return;
        }

        if (prefersReducedMotion()) {
            tabAdvanceTimeout = setTimeout(() => {
                setActive((currentIndex + 1) % buttons.length);
            }, tabAutoMs);
            return;
        }

        const indexAtStart = currentIndex;
        const t0 = performance.now();

        setIndicatorProgress(0);
        indicatorStroke.classList.add('is-timing');

        function tick() {
            if (indexAtStart !== currentIndex) {
                return;
            }
            if (!indicatorStroke.classList.contains('is-timing')) {
                return;
            }
            const p = (performance.now() - t0) / tabAutoMs;
            if (p >= 1) {
                setIndicatorProgress(1);
                tabArcRaf = null;
                setActive((currentIndex + 1) % buttons.length);
                return;
            }
            setIndicatorProgress(p);
            tabArcRaf = requestAnimationFrame(tick);
        }

        tabArcRaf = requestAnimationFrame(tick);
    }

    function setActive(index) {
        const n = ((index % buttons.length) + buttons.length) % buttons.length;
        const activeBtn = buttons[n];
        const activeContent = contents[n];

        if (!activeBtn || !activeContent) {
            return;
        }

        currentIndex = n;

        document.querySelector('.carousel-switches button.active')?.classList.remove('active');
        document.querySelector('.tab-pane-container.active')?.classList.remove('active');

        activeBtn.classList.add('active');
        activeContent.classList.add('active');
        syncCarouselLayout();
        restartTabTimer();
    }

    function onInViewOrVisibility() {
        if (canAutoPlay()) {
            syncCarouselLayout();
            restartTabTimer();
        } else {
            stopTabTimer();
            indicatorStroke.classList.remove('is-timing');
        }
    }

    const observer = new IntersectionObserver(
        (entries) => {
            isCarouselInView = entries.some((entry) => entry.isIntersecting);
            onInViewOrVisibility();
        },
        { threshold: 0, rootMargin: '0px' }
    );
    observer.observe(carousel);

    const rect = carousel.getBoundingClientRect();
    isCarouselInView = rect.top < window.innerHeight && rect.bottom > 0;

    buttons.forEach((btn, index) => {
        btn.addEventListener('click', () => {
            setActive(index);
        });
    });

    setActive(0);
    onInViewOrVisibility();

    requestAnimationFrame(() => {
        requestAnimationFrame(() => {
            syncCarouselLayout();
            onInViewOrVisibility();
        });
    });

    document.addEventListener('visibilitychange', onInViewOrVisibility);

    window.addEventListener('resize', () => {
        syncCarouselLayout();
    });
});

function initGridSlider() {
    const grid = document.querySelector('.grid-items');
    const dotsContainer = document.querySelector('.slider-dots');

    if (!grid || !dotsContainer) return;

    dotsContainer.innerHTML = '';

    if (window.innerWidth <= 700 && !grid.classList.contains('mobile-ready')) {
        const items = document.querySelectorAll('.grid-item');

        items.forEach((item) => {
            const boxes = item.querySelectorAll('.relative-box');

            boxes.forEach((box) => {
                grid.appendChild(box);
            });

            item.remove();
        });

        grid.classList.add('mobile-ready');
    }

    const slides = Array.from(grid.querySelectorAll('.relative-box')).filter(
        (el) => getComputedStyle(el).display !== 'none'
    );

    slides.forEach((_, i) => {
        const dot = document.createElement('span');
        dot.className = 'dot';
        if (i === 0) dot.classList.add('active');

        dot.addEventListener('click', () => {
            grid.scrollTo({
                left: i * grid.clientWidth,
                behavior: 'smooth'
            });
        });

        dotsContainer.appendChild(dot);
    });

    const dots = dotsContainer.querySelectorAll('.dot');

    grid.addEventListener('scroll', () => {
        const index = Math.round(grid.scrollLeft / grid.clientWidth);

        dots.forEach((dot) => dot.classList.remove('active'));
        if (dots[index]) dots[index].classList.add('active');
    });
}

window.addEventListener('load', initGridSlider);
window.addEventListener('resize', () => {
    if (window.innerWidth <= 700) {
        initGridSlider();
    }
});

document.querySelectorAll('.testimonial-track').forEach((track) => {
    const testimonialSets = Array.from(track.children);
    let firstOriginalItem;
    let firstClonedItem;

    testimonialSets.forEach((set, index) => {
        const clone = set.cloneNode(true);
        clone.setAttribute('aria-hidden', 'true');
        if (index === 0) {
            firstClonedItem = clone.querySelector('.testimonial-item');
        }
        track.appendChild(clone);
    });

    const updateScrollDistance = () => {
        firstOriginalItem = track.querySelector('.testimonial-item');
        if (!firstOriginalItem || !firstClonedItem) return;

        const distance = firstClonedItem.getBoundingClientRect().left - firstOriginalItem.getBoundingClientRect().left;
        track.style.setProperty('--testimonial-scroll-distance', `${distance}px`);
        track.classList.add('is-ready');
    };

    updateScrollDistance();
    requestAnimationFrame(updateScrollDistance);
    window.addEventListener('load', updateScrollDistance);
    window.addEventListener('resize', updateScrollDistance);

    if (document.fonts) {
        document.fonts.ready.then(updateScrollDistance);
    }
});

document.querySelectorAll('.testimonial-slider').forEach((slider) => {
    let longPressTimer;
    let longPressed = false;
    let pointerMoved = false;
    let startX = 0;
    let startY = 0;

    const isTouchInput = (event) => event.pointerType === 'touch' || event.pointerType === 'pen';

    slider.addEventListener('pointerdown', (event) => {
        if (!isTouchInput(event)) return;

        startX = event.clientX;
        startY = event.clientY;
        longPressed = false;
        pointerMoved = false;

        slider.classList.add('is-touch-paused');

        clearTimeout(longPressTimer);
        longPressTimer = setTimeout(() => {
            longPressed = true;
            slider.classList.add('is-paused');
        }, 450);
    });

    slider.addEventListener('pointermove', (event) => {
        if (!isTouchInput(event)) return;

        const moveX = Math.abs(event.clientX - startX);
        const moveY = Math.abs(event.clientY - startY);

        if (moveX > 10 || moveY > 10) {
            pointerMoved = true;
            clearTimeout(longPressTimer);
        }
    });

    slider.addEventListener('pointerup', (event) => {
        if (!isTouchInput(event)) return;

        clearTimeout(longPressTimer);
        slider.classList.remove('is-touch-paused');

        if (!pointerMoved && !longPressed) {
            slider.classList.toggle('is-paused');
        }
    });

    slider.addEventListener('pointercancel', () => {
        clearTimeout(longPressTimer);
        slider.classList.remove('is-touch-paused');
    });
});

(function initFaq() {
    const faqItems = document.querySelectorAll('.faq-item');

    function openAnswer(item, answer) {
        item.classList.add('open');
        answer.style.overflow = 'hidden';
        answer.style.height = `${answer.scrollHeight}px`;

        answer.addEventListener('transitionend', function onTransitionEnd() {
            if (item.classList.contains('open')) {
                answer.style.height = 'auto';
                answer.style.overflow = 'visible';
            }
            answer.removeEventListener('transitionend', onTransitionEnd);
        });
    }

    function closeAnswer(item, answer) {
        answer.style.overflow = 'hidden';
        answer.style.height = `${answer.scrollHeight}px`;
        answer.offsetHeight;
        item.classList.remove('open');
        answer.style.height = '0px';
    }

    faqItems.forEach((item) => {
        const question = item.querySelector('.faq-item-question');
        const answer = item.querySelector('.faq-item-answer');

        if (!question || !answer) return;

        question.setAttribute('role', 'button');
        question.setAttribute('tabindex', '0');
        question.setAttribute('aria-expanded', 'false');

        const toggleItem = () => {
            const isOpen = item.classList.contains('open');

            if (isOpen) {
                closeAnswer(item, answer);
                question.setAttribute('aria-expanded', 'false');
            } else {
                openAnswer(item, answer);
                question.setAttribute('aria-expanded', 'true');
            }
        };

        item.addEventListener('click', toggleItem);
        question.addEventListener('keydown', (event) => {
            if (event.key !== 'Enter' && event.key !== ' ') return;

            event.preventDefault();
            event.stopPropagation();
            toggleItem();
        });
    });
})();
